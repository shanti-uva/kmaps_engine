class Admin::FeatureRelationsController < ApplicationController
  include KmapsEngine::ResourceObjectAuthentication
  resource_controller
  cache_sweeper :feature_sweeper, :only => [:create, :update, :destroy]
  belongs_to :feature
  
  new_action.before do |c|
    c.send :setup_for_new_relation
    get_perspectives
  end
  
  edit.before do
    get_perspectives
  end
  
  update do
    failure.wants.html do
      get_perspectives
      render action: 'edit'
    end
  end
  
  destroy.wants.html { redirect_to admin_feature_url(parent_object.fid) }
  
  create do
    wants.html { redirect_to(polymorphic_url [:admin, parent_object, object]) }
    failure.wants.html do
      get_perspectives
      render action: 'new'
    end
  end

  new_action.wants.html { redirect_if_unauthorized }
  
  protected
  
  # Only allow a trusted parameter "white list" through.
  def feature_relation_params
    process_feature_relation_type_id_mark
    params.require(:feature_relation).permit(:perspective_id, :parent_node_id, :child_node_id, :feature_relation_type_id)
  end
  
  def get_perspectives
    @perspectives = parent_object.affiliations_by_user(AuthenticatedSystem::Current.user, descendants: true).collect(&:perspective)
    @perspectives = Perspective.order(:name) if AuthenticatedSystem::Current.user.admin? || @perspectives.blank?
  end
  
  private
  
  def collection
    feature_id = params[:feature_id]
    search_results = FeatureRelation.search(params[:filter])
    search_results = search_results.where(['parent_node_id = ? OR child_node_id = ?', feature_id, feature_id]) if feature_id
    @collection = search_results.page(params[:page])
  end
  
  #
  # Need to override the ResourceController::Helpers.parent_association method
  # to get the correct name of the parent association
  # Reminder: This is a subclass of ResourceController::Base
  #
  def parent_association
    if params[:id].nil?
      return parent_object.all_parent_relations 
    end
    # Gotta find it seperately, will get a recursive stack error elsewise
    o = FeatureRelation.find(params[:id])
    parent_object.id == o.parent_node.id ? parent_object.all_child_relations : parent_object.all_parent_relations
  end
  
  def setup_for_new_relation
    object.child_node = parent_object # ResourceController can't seem to set this up?
    object.parent_node = Feature.find(params[:target_id])
  end
  
  def process_feature_relation_type_id_mark
    if params[:feature_relation][:feature_relation_type_id] =~ /^_/
      swap_temp = params[:feature_relation][:child_node_id]
      params[:feature_relation][:child_node_id] = params[:feature_relation][:parent_node_id]
      params[:feature_relation][:parent_node_id] = swap_temp
    end
    params[:feature_relation][:feature_relation_type_id] = params[:feature_relation][:feature_relation_type_id].gsub(/^_/, '')
  end
  
  ActiveSupport.run_load_hooks(:admin_feature_relations_controller, Admin::FeatureRelationsController)
end
