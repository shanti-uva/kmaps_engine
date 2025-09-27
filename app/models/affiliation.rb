# == Schema Information
#
# Table name: affiliations
#
#  id             :bigint           not null, primary key
#  descendants    :boolean          default(TRUE), not null
#  created_at     :datetime
#  updated_at     :datetime
#  collection_id  :integer          not null
#  feature_id     :integer          not null
#  perspective_id :integer
#
# Indexes
#
#  affiliations_on_dependencies  (collection_id,feature_id,perspective_id) UNIQUE
#

class Affiliation < ActiveRecord::Base
  attr_accessor :skip_update
  
  belongs_to :collection
  belongs_to :feature, touch: true
  belongs_to :perspective, optional: true
  
  validates_uniqueness_of :collection_id, scope: :feature_id
  
  after_create do |record|
    if !record.skip_update && record.descendants?
      perspective = record.perspective
      descendants = record.perspective.nil? ? record.feature.all_descendants : record.feature.descendants_by_perspective_with_parent(record.perspective).collect(&:first)
      descendants.each do |f|
        options = {collection_id: record.collection.id, feature_id: f.id, perspective_id: perspective&.id}
        a = Affiliation.where(options).first
        Affiliation.create(options.merge(skip_update: true)) if a.nil?
      end
    end
  end
  
  before_destroy do |record|
    if !record.skip_update && record.valid? && record.descendants?
      perspective = record.perspective
      descendants = record.perspective.nil? ? record.feature.all_descendants : record.feature.descendants_by_perspective_with_parent(record.perspective).collect(&:first)
      descendants.each do |f|
        Affiliation.where(collection_id: record.collection.id, feature_id: f.id, perspective_id: perspective&.id).delete_all
      end
    end
  end
  
  before_update do |record|
    return if record.skip_update
    if record.descendants_changed?
      if record.descendants?
        perspective = record.perspective
        descendants = record.perspective.nil? ? record.feature.all_descendants : record.feature.descendants_by_perspective_with_parent(record.perspective).collect(&:first)
        descendants.each do |f|
          options = {collection_id: record.collection.id, feature_id: f.id, perspective_id: perspective&.id}
          a = Affiliation.where(options).first
          Affiliation.create(options.merge(skip_update: true)) if a.nil?
        end
      else
        perspective_id = record.perspective_id_was
        perspective = perspective_id.nil? ? nil : Perspective.find(perspective_id)
        descendants = record.perspective.nil? ? record.feature.all_descendants : record.feature.descendants_by_perspective_with_parent(record.perspective).collect(&:first)
        descendants.each do |f|
          Affiliation.where(collection_id: record.collection.id, feature_id: f.id, perspective_id: perspective_id).delete_all
        end
      end
    elsif record.perspective_id_changed?
      perspective_id = record.perspective_id_was
      perspective = perspective_id.nil? ? nil : Perspective.find(perspective_id)
      descendants = record.perspective.nil? ? record.feature.all_descendants : record.feature.descendants_by_perspective_with_parent(record.perspective).collect(&:first)
      descendants.each do |f|
        Affiliation.where(collection_id: record.collection.id, feature_id: f.id, perspective_id: perspective_id).delete_all
      end
      
      perspective = record.perspective
      descendants = record.perspective.nil? ? record.feature.all_descendants : record.feature.descendants_by_perspective_with_parent(record.perspective).collect(&:first)
      descendants.each do |f|
        options = {collection_id: record.collection.id, feature_id: f.id, perspective_id: perspective&.id}
        a = Affiliation.where(options).first
        Affiliation.create(options.merge(skip_update: true)) if a.nil?
      end
    elsif record.collection_id_changed?
      perspective = record.perspective
      descendants = record.perspective.nil? ? record.feature.all_descendants : record.feature.descendants_by_perspective_with_parent(record.perspective).collect(&:first)
      descendants.each do |f|
        options = {collection_id: record.collection_id_was, feature_id: f.id, perspective_id: perspective&.id}
        Affiliation.where(options).update_all(collection_id: record.collection_id)
      end
    end
  end
end
