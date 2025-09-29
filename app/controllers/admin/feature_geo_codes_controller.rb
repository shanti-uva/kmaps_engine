class Admin::FeatureGeoCodesController < ApplicationController
  include KmapsEngine::ResourceObjectAuthentication
  resource_controller
  belongs_to :feature
  
  protected
  
  def parent_association
    parent_object.geo_codes
  end
  
  def collection
    feature_id=params[:feature_id]
    search_results = FeatureGeoCode.search(params[:filter])
    search_results = search_results.where(['feature_id = ?', feature_id]) if feature_id
    @collection = search_results.page(params[:page])
  end
  
  # Only allow a trusted parameter "white list" through.
  def feature_geo_code_params
    params.require(:feature_geo_code).permit(:geo_code_type_id, :geo_code_value)
  end
end