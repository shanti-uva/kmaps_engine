class Admin::ViewsController < ApplicationController
  allow_unauthenticated_access only: :index
  resource_controller
  include KmapsEngine::SimplePropsControllerHelper
  caches_page :index, :if => Proc.new { |c| c.request.format.xml? || c.request.format.json? }
  cache_sweeper :view_sweeper, :only => [:update, :destroy]
  
  index.wants.xml { render xml: JSON.parse(@collection.to_json).to_xml(root: :views) }
  index.wants.json { render :json => @collection }
  
  protected
  
  # Only allow a trusted parameter "white list" through.
  def view_params
    params.require(:view).permit(:name, :code, :description)
  end
end