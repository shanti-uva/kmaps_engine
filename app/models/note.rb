# == Schema Information
#
# Table name: notes
#
#  id                :bigint           not null, primary key
#  association_type  :string
#  content           :text             not null
#  custom_note_title :string
#  is_public         :boolean          default(TRUE)
#  notable_type      :string           not null
#  created_at        :datetime
#  updated_at        :datetime
#  notable_id        :integer          not null
#  note_title_id     :integer
#

class Note < ActiveRecord::Base
  # Included for use of model_display_name in notable_type_name.  Is there
  # a better approach to this?
  include ApplicationHelper
  
  belongs_to :notable, polymorphic: true, touch: true
  belongs_to :note_title, optional: true
  has_and_belongs_to_many :authors, class_name: 'AuthenticatedSystem::Person', join_table: 'authors_notes', association_foreign_key: 'author_id'
  has_many :imports, as: 'item', dependent: :destroy

  validates_presence_of :content
  
  accepts_nested_attributes_for :authors
  
  before_save :determine_title
  
  # AssociationNote uses single-table inheritance from Note, so we need to make sure that no AssociationNotes are
  # returned by .find.
  def self.default_scope
    where(:association_type => nil)
  end
  
  def title
    self.custom_note_title.blank? ? (self.note_title&.title) : self.custom_note_title
  end
  
  def notable_type_name
    notable_type.blank? ? '' : model_display_name(notable_type.tableize.singularize)
  end
  
  def to_s
    return self.title.nil? ? "Note" : self.title.to_s
  end
  
  def self.search(filter_value)
    self.where(build_like_conditions(%W(notes.content notes.custom_note_title note_titles.title), filter_value)).includes(:note_title).references(:note_title)
  end
  
  def rsolr_document_tags(document, prefix = '')
    title = self.title
    prefix_ = prefix.blank? ? '' : "#{prefix}_"
    document["#{prefix_}note_#{self.id}_title_s"] if !title.blank?
    authors = self.authors
    document["#{prefix_}note_#{self.id}_authors_ss"] = authors.collect(&:fullname) if !authors.blank?
    document["#{prefix_}note_#{self.id}_content_t"] = self.content
  end
  
  def feature
    self.notable.feature
  end
  
  private
  
  # Notes can have one of two types of titles: a custom title, or a title from the list of note_titles.
  # When saving a note, we want only one title.  We give preference to note_title_id by setting
  # custom_note_title = "" if note_title_id is set.
  def determine_title
    unless self.note_title_id.blank?
      self.custom_note_title = ""
    end
  end
end
