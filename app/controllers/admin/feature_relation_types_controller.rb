class Admin::FeatureRelationTypesController < ApplicationController
  resource_controller
  #before_action :collection
  
  create.before { object.asymmetric_label = object.label if object.is_symmetric }
  update.before { object.asymmetric_label = object.label if object.is_symmetric }
  create.wants.html { redirect_to polymorphic_url([:admin, object]) }
  update.wants.html { redirect_to polymorphic_url([:admin, object]) }
  destroy.wants.html { redirect_to admin_feature_relation_types_url }

  protected
  
  def collection
    @collection = FeatureRelationType.search(params[:filter]).page(params[:page])
  end
  
  # Only allow a trusted parameter "white list" through.
  def feature_relation_type_params
    params.require(:feature_relation_type).permit(:is_hierarchical, :is_symmetric, :label, :asymmetric_label, :code, :asymmetric_code)
  end
  
  ActiveSupport.run_load_hooks(:admin_feature_relation_types_controller, Admin::FeatureRelationTypesController)
end
