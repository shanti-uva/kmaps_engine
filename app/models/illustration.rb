# == Schema Information
#
# Table name: illustrations
#
#  id           :bigint           not null, primary key
#  is_primary   :boolean          default(TRUE), not null
#  picture_type :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  feature_id   :integer          not null
#  picture_id   :integer          not null
#

class Illustration < ActiveRecord::Base
  belongs_to :feature, touch: true
  belongs_to :picture, :polymorphic => true
  
  before_destroy {|record| record.picture.destroy if record.picture.instance_of?(ExternalPicture)}
  
  #
  #
  # Validation
  #
  #
  validates :picture_id, presence: true
  validate :presence_of_external_picture
  
  def presence_of_external_picture
    picture = self.picture
    picture_type = self.picture_type
    if picture_type.start_with?('MmsIntegration') || picture_type.start_with?('ShantiIntegration')
      errors.add(:base, 'Record could not be found!') if picture.nil?
    end
    picture.errors.to_a.each { |e| self.errors.add(:base, e) } if !picture.nil? && !picture.valid?
  end
  
  alias :_picture picture
  def picture
    case self.picture_type
    when 'MmsIntegration::Picture'
      MmsIntegration::Picture.find(picture_id)
    when 'ShantiIntegration::Image'
      ShantiIntegration::Image.find(picture_id)
    else
      _picture
    end
  end
  
  def thumb_url
    case self.picture_type
    when 'ShantiIntegration::Image'
      picture.url_thumb
    when 'MmsIntegration::Picture'
      picture.image.url
    else
      picture.url
    end
  end
  
  def picture_url
    case self.picture_type
    when 'ShantiIntegration::Image'
      picture.url_html
    when 'MmsIntegration::Picture'
      picture.get_url(nil, :format => '')
    else
      picture.url
    end
  end
  
  def picture_uid
    case self.picture_type
    when 'ShantiIntegration::Image'
      return picture.uid
    when 'MmsIntegration::Picture'
      return "mms-#{self.picture_id}"
    end
    return ''
  end
  
  def to_s
    self.picture_url
  end
  
  def ensure_one_primary
    parent = self.feature
    primary_illustrations = parent.illustrations.where(:is_primary => true)
    case primary_illustrations.count
    when 0
      parent.illustrations.order('updated_at ASC').first.update_attribute(:is_primary, true)
    when 1
    else
      keep = self.is_primary? ? self : primary_illustrations.order('updated_at DESC').first
      primary_illustrations.where(['id <> ?', keep.id]).update_all(:is_primary => false) if !keep.nil?
    end
  end
end