class Admin::IllustrationsController < ApplicationController
  include KmapsEngine::ResourceObjectAuthentication
  resource_controller
  belongs_to :feature
  
  create.before do
    if params[:picture_type]=='MmsIntegration::Picture' || params[:picture_type]=='ShantiIntegration::Image'
      object.picture_type = params[:picture_type]
    else
      object.picture = ExternalPicture.create(external_picture_params)
    end
  end
  
  create.after { object.ensure_one_primary }
  
  # This callback should be unnecesary, but unfortunately as of Rails 5.2, nested attributes don't seem to work with
  # a polymorphic belongs_to relationship. This is unrelated to resource controller.
  update.before do
    picture_params = params[:illustration][:picture].permit(:caption, :url, :place_id)
    params[:illustration].delete(:picture)
    object.picture.update(picture_params)
  end
  
  update.after { object.ensure_one_primary }
  
  destroy.after do
    primary_illustrations = parent_object.illustrations.where(:is_primary => true)
    case primary_illustrations.count
    when 0
      other = parent_object.illustrations.order('updated_at ASC').first
      other.update_attribute(:is_primary, true) if !other.nil?
    when 1
    else
      keep = primary_illustrations.order('updated_at ASC').first
      primary_illustrations.where(['id <> ?', keep.id]).update_all(:is_primary => false) if !keep.nil?
    end
  end
  
  protected
  
  def parent_association
    parent_object.illustrations
  end
  
  # Only allow a trusted parameter "white list" through.
  def external_picture_params
    params.require(:external_picture).permit(:caption, :url, :place_id)
  end
  
  # Only allow a trusted parameter "white list" through.
  def illustration_params
    params.require(:illustration).permit(:feature_id, :is_primary, :picture_id, :picture_type)
  end
end