class Admin::ImportationTasksController < ApplicationController
  resource_controller
  
  def collection
    @collection = ImportationTask.search(params[:filter]).page(params[:page])
  end
  
  protected
  
  # Only allow a trusted parameter "white list" through.
  def importation_task_params
    params.require(:importation_task).permit(:task_code)
  end
end
