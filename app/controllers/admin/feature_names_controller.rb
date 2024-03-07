class Admin::FeatureNamesController < AclController
  include KmapsEngine::ResourceObjectAuthentication
  resource_controller
  
  cache_sweeper :feature_sweeper, :only => [:create, :update, :destroy]
  belongs_to :feature
  before_action :collection, :only=>:locate_for_relation
  
  def initialize
    super
    @guest_perms = []
  end
  
  def locate_for_relation
    @locating_relation=true # flag used in template
    # Remove the Feature that is currently looking for a relation
    # (shouldn't relate to itself)
    @collection = @collection.where(['id <> ?', object.id])
    render :action => 'index'
  end
  
  def prioritize
    @feature = Feature.find(params[:id])
  end
  
  def set_priorities
    feature = Feature.find(params[:id])
    changed = false
    feature.names.each do |name|
      name.position = params[:feature_name].index(name.id.to_s) + 1
      if name.position_changed?
        name.skip_update = true
        name.save
        changed = true
      end
    end
    if changed
      feature.update_is_name_position_overriden
      feature.update_cached_feature_names
    end
    render plain: ''
  end
  
  # Overwrite the default destroy method so we can redirect_to(:back)
  def destroy
    name = FeatureName.find(params[:id])
    name.destroy
    redirect_back(fallback_location: admin_root_path)
  end
  
  protected
  
  #
  # Need to override the ResourceController::Helpers.parent_association method
  # to get the correct name of the parent association
  #
  def parent_association
    parent_object.names
  end
  
  #
  # Override ResourceController collection method
  #
  def collection
    feature_id=nil
    if params[:feature_id]
      feature_id = params[:feature_id]
    elsif params[:id]
      feature_id = object.feature_id
    end
    search_results = FeatureName.search(params[:filter])
    search_results = search_results.where(:feature_id => feature_id) if feature_id
    @collection = search_results.page(params[:page])
  end
  
  # Only allow a trusted parameter "white list" through.
  def feature_name_params
    params.require(:feature_name).permit(:name, :feature_name_type_id, :language_id, :writing_system_id, :etymology, :feature_name, :is_primary_for_romanization, :ancestor_ids, :skip_update, :feature_id, :position)
  end
end
