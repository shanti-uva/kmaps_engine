# == Schema Information
#
# Table name: perspectives
#
#  id          :bigint           not null, primary key
#  code        :string
#  description :text
#  is_public   :boolean          default(FALSE)
#  name        :string
#  notes       :text
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_perspectives_on_code  (code)
#

class Perspective < ActiveRecord::Base
  include KmapsEngine::SimplePropCache

  #
  #
  # Associations
  #
  #
  include KmapsEngine::IsCitable
  extend KmapsEngine::HasTimespan
  
  #
  #
  # Validation
  #
  #
  validates_presence_of :name
  validates_format_of :code, :with=>/\w+/
  validates_uniqueness_of :code
      
  def to_s
    name
  end
  
  def self.name_and_id_list
    self.all.collect {|ft| [ft.name, ft.id] }
  end
  
  def self.search(filter_value)
    self.where(build_like_conditions(%W(simple_props.name simple_props.code simple_props.description simple_props.notes), filter_value))
  end

  def self.find_all_public
    self.where(:is_public => true).order('name')
  end
  
  def self.update_or_create(attributes)
    r = self.find_by(code: attributes[:code])
    r.nil? ? self.create(attributes) : r.update(attributes)
  end
end
