class Admin::CitationsController < AclController
  resource_controller
  belongs_to :description, :feature, :feature_name, :feature_relation, :feature_name_relation, :feature_geo_code
  before_action :collection
  
  def initialize
    super
    @guest_perms = []
  end
  
  create.wants.html { redirect_to polymorphic_url([:admin, object.citable, object]) }
  update.wants.html { redirect_to polymorphic_url([:admin, object.citable, object]) }
  destroy.wants.html { redirect_to polymorphic_url([:admin, object.citable]) }
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
