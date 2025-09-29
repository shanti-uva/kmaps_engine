class Admin::BlurbsController < ApplicationController
  resource_controller
  
  def collection
    @collection = Blurb.search(params[:filter]).page(params[:page])
  end
  
  protected
  
  # Only allow a trusted parameter "white list" through.
  def blurb_params
    params.require(:blurb).permit(:title, :code, :content)
  end
end
