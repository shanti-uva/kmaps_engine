# == Schema Information
#
# Table name: descriptions
#
#  id          :bigint           not null, primary key
#  content     :text             not null
#  is_primary  :boolean          default(FALSE), not null
#  source_url  :string
#  title       :string
#  created_at  :datetime
#  updated_at  :datetime
#  feature_id  :integer          not null
#  language_id :integer          not null
#

class Description < ActiveRecord::Base
  validates_presence_of :content, :feature_id, :language_id
  #belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
  belongs_to :feature, touch: true
  belongs_to :language
  has_and_belongs_to_many :authors, :class_name => 'AuthenticatedSystem::Person', :join_table => 'authors_descriptions', :association_foreign_key => 'author_id'
  has_many :imports, :as => 'item', :dependent => :destroy
  
  accepts_nested_attributes_for :authors
  
  include KmapsEngine::IsCitable
  include KmapsEngine::IsNotable
  extend IsDateable

  def self.search(filter_value)
    self.where(build_like_conditions(%W(description.content), filter_value))
  end
  
  def to_s
    title
  end
end
