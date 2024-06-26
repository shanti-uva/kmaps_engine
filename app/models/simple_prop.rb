# == Schema Information
#
# Table name: simple_props
#
#  id          :bigint           not null, primary key
#  code        :string
#  description :text
#  name        :string
#  notes       :text
#  type        :string
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  simple_props_code_idx  (code)
#  simple_props_type_idx  (type)
#

# now Language has all attributes and methods of SimpleProp
# end
#
# The class name that extends SimpleProp is stored in the :type column
# All data is stored in simple_props
# See Rails STI (Single Table Inheritance)
#
class SimpleProp < ActiveRecord::Base
  include KmapsEngine::SimplePropCache

  #
  #
  # Associations
  #
  #
  
  #
  #
  # Validation
  #
  #
  validates_format_of :code, :with=>/\w+/
  # Validate only within the same class type
  validates_uniqueness_of :code, :scope=>:type
  
  def self.update_or_create(attributes)
    r = self.find_by(code: attributes[:code])
    r.nil? ? self.create(attributes) : r.update(attributes)
  end
  
  def self.name_and_id_list
    self.all.collect {|ft| [ft.name, ft.id] }
  end
  
  def to_s
    [name, code, 'n/a'].detect {|i| ! i.blank? }
  end
  
  def self.search(filter_value)
    self.where(build_like_conditions(%W(simple_props.name simple_props.code simple_props.description simple_props.notes), filter_value))
  end  
end
