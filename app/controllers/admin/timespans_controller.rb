class Admin::TimespansController < ApplicationController
  resource_controller
  
  def collection
    @collection = Timespan.search(params[:filter]).page(params[:page])
  end
  
  protected
  
  # Only allow a trusted parameter "white list" through.
  def timespan_params
    params.require(:timespan).permit(:is_current)
  end
end