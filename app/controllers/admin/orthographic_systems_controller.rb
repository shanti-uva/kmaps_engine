class Admin::OrthographicSystemsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  resource_controller
  include KmapsEngine::SimplePropsControllerHelper
  
  protected
  
  # Only allow a trusted parameter "white list" through.
  def orthographic_system_params
    params.require(:orthographic_system).permit(:name, :code, :description)
  end
end