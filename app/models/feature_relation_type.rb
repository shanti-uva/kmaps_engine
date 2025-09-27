# == Schema Information
#
# Table name: feature_relation_types
#
#  id               :bigint           not null, primary key
#  asymmetric_code  :string
#  asymmetric_label :string
#  code             :string           not null
#  is_hierarchical  :boolean          default(FALSE), not null
#  is_symmetric     :boolean
#  label            :string           not null
#  created_at       :datetime
#  updated_at       :datetime
#  branch_id        :integer
#

class FeatureRelationType < ActiveRecord::Base
  has_many :feature_relations, :dependent => :destroy
  has_many :imports, as: 'item', dependent: :destroy
  
  before_save :set_asymmetric_label
  
  def set_asymmetric_label
    asymmetric_label = label if is_symmetric
  end
  
  def self.update_or_create(attributes)
    r = self.find_by(code: attributes[:code])
    r.nil? ? self.create(attributes) : r.update(attributes)
  end
  
  # Creates options for a select, marking either the asymmetric label or the original label's id
  # with a prefix of "_", which can be detected and used for switching the parent and child node
  # ids if the relation being selected requires it.
  def self.marked_options(mark_asymmetric: true, include_hierarchical: true)
    options = []
    types = FeatureRelationType.order(:id)
    types = types.where(is_hierarchical: false) if !include_hierarchical
    types.each do |type|
      if type.is_symmetric
        options.push([type.label, type.id])
      else
        if mark_asymmetric
          options.push([type.label, type.id], [type.asymmetric_label, "_#{type.id}"])
        else
          options.push([type.label, "_#{type.id}"], [type.asymmetric_label, type.id])
        end
      end
    end
    options
  end
  
  # This returns the id of the FeatureRelationType that should be used in acts_as_family_tree. It
  # may be better to make a dedicated, boolean "is_hierarchical" column in feature_relation_types
  # that is only set to TRUE for this type, and use that to determine which type is used.
  # This seems to be generally satisfactory for now, since a migration creates the initial
  # FeatureRelationTypes.
  def self.hierarchy_ids
    Rails.cache.fetch('feature_relation_types/hierarchical_ids', :expires_in => 1.day) { self.table_exists? ? self.where(:is_hierarchical => true).order(:id).collect(&:id) : nil }
  end
  
  def to_s
    is_symmetric ? label : "#{label}/#{asymmetric_label}"
  end
  
  def self.search(filter_value)
    self.where(build_like_conditions(%W(feature_relation_types.label feature_relation_types.asymmetric_label), filter_value))
  end
  
  def self.get_by_code(code)
    frt_id = Rails.cache.fetch("feature_relation_types/code/#{code}", :expires_in => 1.day) do
      frt = self.find_by(code: code)
      frt&.id
    end
    frt_id.nil? ? nil : FeatureRelationType.find(frt_id)
  end
  
  def self.get_by_asymmetric_code(code)
    frt_id = Rails.cache.fetch("feature_relation_types/asymmetric_code/#{code}", :expires_in => 1.day) do
      frt = self.find_by(asymmetric_code: code)
      frt&.id
    end
    frt_id.nil? ? nil : FeatureRelationType.find(frt_id)
  end
  
  ActiveSupport.run_load_hooks(:feature_relation_type, FeatureRelationType)
end
