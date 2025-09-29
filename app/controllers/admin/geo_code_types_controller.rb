class Admin::GeoCodeTypesController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  resource_controller
  include KmapsEngine::SimplePropsControllerHelper
  
  protected
  
  # Only allow a trusted parameter "white list" through.
  def geo_code_type_params
    params.require(:geo_code_type).permit(:name, :code, :description)
  end
end