# == Schema Information
#
# Table name: feature_name_relations
#
#  id                     :bigint           not null, primary key
#  ancestor_ids           :string
#  is_alt_spelling        :integer
#  is_orthographic        :integer
#  is_phonetic            :integer
#  is_translation         :integer
#  created_at             :datetime
#  updated_at             :datetime
#  alt_spelling_system_id :integer
#  child_node_id          :integer          not null
#  orthographic_system_id :integer
#  parent_node_id         :integer          not null
#  phonetic_system_id     :integer
#
# Indexes
#
#  feature_name_relations_child_node_id_idx   (child_node_id)
#  feature_name_relations_parent_node_id_idx  (parent_node_id)
#

class FeatureNameRelation < ActiveRecord::Base
  attr_accessor :skip_update

  acts_as_family_tree :tree, nil, :node_class=>'FeatureName'
  
  after_save do |record|
    if !record.skip_update
      # we could update this object's (a FeatureRelation) hierarchy but the THL Places-app doesn't use that info in any way yet
      [record.parent_node, record.child_node].each {|r| r.queued_update_hierarchy }
      feature = record.feature
      feature.update_name_positions
      views = feature.update_cached_feature_names
    end
  end
  
  after_destroy do |record|
    if !record.skip_update
      # we could update this object's (a FeatureRelation) hierarchy but the THL Places-app doesn't use that info in any way yet
      [record.parent_node, record.child_node].each {|r| r.queued_update_hierarchy }
      feature = record.feature
      views = feature.update_cached_feature_names
    end
  end
  
  #TYPES=[
  #  
  #]
  
  #
  #
  # Associations
  #
  #
  extend KmapsEngine::HasTimespan
  include KmapsEngine::IsCitable
  include KmapsEngine::IsNotable
  
  belongs_to :perspective, optional: true
  belongs_to :phonetic_system, optional: true
  belongs_to :alt_spelling_system, optional: true
  belongs_to :orthographic_system, optional: true
  has_many :imports, :as => 'item', :dependent => :destroy
  
  def to_s
    "\"#{child_node}\" relation to \"#{parent_node}\""
  end
  
  def display_string
    return "phonetic-#{phonetic_system.name.downcase}" unless phonetic_system.blank?
    return "orthographic-#{orthographic_system.name.downcase}" unless orthographic_system.blank?
    return "alt-spelling-#{alt_spelling_system.name.downcase}" unless alt_spelling_system.blank?
    return "translation" unless is_translation.blank?
    "Unknown Relation"
  end
  
  def relationship
    return phonetic_system unless phonetic_system.blank?
    return orthographic_system unless orthographic_system.blank?
    return alt_spelling_system unless alt_spelling_system.blank?
    return "translation" unless is_translation.blank?
    "unknown"
  end
  
  def pp_display_string
    return "Transcription-#{phonetic_system.name}" unless phonetic_system.blank?
    return "Transliteration-#{orthographic_system.name}" unless orthographic_system.blank?
    return "Alt Spelling-#{alt_spelling_system.name}" unless alt_spelling_system.blank?
    return "Translation" unless is_translation.blank?
    "Unknown Relation"
  end
  
  #
  # Returns the feature that owns this FeatureNameRelation
  #
  def feature
    return self.child_node.feature if !self.child_node.nil?
    return self.parent_node.feature if !self.parent_node.nil?
    return nil
  end
  
  def self.search(filter_value)
    self.where(build_like_conditions(%W(children.name parents.name), filter_value)
    ).joins('LEFT JOIN feature_names parents ON parents.id=feature_name_relations.parent_node_id LEFT JOIN feature_names children ON children.id=feature_name_relations.child_node_id')
  end
end
