# == Schema Information
#
# Table name: citations
#
#  id               :bigint           not null, primary key
#  citable_type     :string           not null
#  info_source_type :string           not null
#  notes            :text
#  created_at       :datetime
#  updated_at       :datetime
#  citable_id       :integer          not null
#  info_source_id   :integer          not null
#
# Indexes
#
#  citations_1_idx               (citable_id,citable_type)
#  citations_info_source_id_idx  (info_source_id)
#

class Citation < ActiveRecord::Base
  include ActiveModel::Validations
  
  attr_accessor :marked_for_deletion
  
  #
  #
  # Associations
  #
  #
  belongs_to :info_source, polymorphic: true
  belongs_to :citable, polymorphic: true, touch: true
  has_many :pages, dependent: :destroy
  has_many :web_pages, dependent: :destroy
  has_many :imports, as: 'item', dependent: :destroy
  
  #
  #
  # Validation
  #
  #
  validates :info_source_id, presence: true
  validate :presence_of_external_info_source
  
  def presence_of_external_info_source
    if self.info_source_type.start_with?('MmsIntegration')
      info_source = self.info_source_type.constantize.find(self.info_source_id)
      errors.add(:base, 'MMS record could not be found!') if info_source.nil?
    elsif self.info_source_type=='ShantiIntegration::Source'
      info_source = self.info_source_type.constantize.find(self.info_source_id)
      errors.add(:base, 'Shanti source record could not be found!') if info_source.nil?
    end
  end
  
  alias :_info_source info_source
  def info_source
    self.info_source_type.start_with?('MmsIntegration') || self.info_source_type=='ShantiIntegration::Source' ? self.info_source_type.constantize.find(self.info_source_id) : _info_source
  end
  
  def to_s
    citable.to_s
  end
  
  def self.search(filter_value)
    self.where(build_like_conditions(%W(citations.notes), filter_value))
  end
  
  def bibliographic_reference
    source = self.info_source
    if self.info_source_type.start_with?('MmsIntegration') && source.type == 'OnlineResource'
      pages = self.web_pages
      if pages.count==1
        source_str = pages.first.full_path
      elsif pages.count > 1
        pages_a = pages.to_a
        e = pages_a.shift
        source_str = ([e.full_path] + a.collect(&:path)).join(', ')
      else
        source_str = source.web_address.url
      end
      source_str = "#{source.prioritized_title} (#{source_str})"
    else
      bibliographic_reference = source.nil? ? self.info_source_id.to_s : source.bibliographic_reference
      source_str = ([bibliographic_reference] + self.pages.collect(&:to_s)).join(', ') + '.'
    end
    return source_str
  end
  
  def rsolr_document_tags_for_notes(document, prefix)
    if !self.notes.blank?
      document["#{prefix}_citation_#{self.id}_note_t"] = self.notes
      document["#{prefix}_citation_#{self.id}_reference_s"] = self.bibliographic_reference
    end
  end
  
  def feature
    self.citable.feature
  end
end
