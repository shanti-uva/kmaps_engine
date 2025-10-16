class Admin::CitationsController < ApplicationController
  resource_controller
  belongs_to :caption, :description, :feature, :feature_geo_code, :feature_name, :feature_name_relation, :feature_relation, :summary
  before_action :collection
  
  new_action.before { object.citable_type = parent_object.class.name }
  create.wants.html { redirect_to polymorphic_url(helpers.stacked_parents) }
  update.wants.html { redirect_to polymorphic_url(helpers.stacked_parents) }
  destroy.wants.html { redirect_to polymorphic_url(helpers.stacked_parents) }
  create.before { object.info_source_type = params[:info_source_type] }
  
  protected
  
  def parent_association
    parent_object.citations # ResourceController needs this for the parent association
  end
  
  def collection
    search_results = Citation.search(params[:filter]) 
    search_results = search_results.where(['citable_id = ? AND citable_type = ?', parent_object.id, parent_object.class.to_s]) if parent?
    @collection = search_results.page(params[:page])
  end
  
  # Only allow a trusted parameter "white list" through.
  def citation_params
    params.require(:citation).permit(:info_source_id, :notes, :citable_id, :citable_type)
  end
end
