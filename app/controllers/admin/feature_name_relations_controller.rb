class Admin::FeatureNameRelationsController < ApplicationController
  include KmapsEngine::ResourceObjectAuthentication
  resource_controller
  belongs_to :feature_name
  
  new_action.before {|c| c.send :setup_for_new_relation}
  
  # We need to update the child FeatureName associated with this relation
  # doing this will setup the ancestor_ids value
  #new_action.after {|c| object.child_node.save}
  #update.after {|c| object.child_node.save}
  
  protected
  
  # Only allow a trusted parameter "white list" through.
  def feature_name_relation_params
    params.require(:feature_name_relation).permit(:is_translation, :is_phonetic, :phonetic_system_id, :is_orthographic, :orthographic_system_id, :is_alt_spelling, :alt_spelling_system_id, :parent_node_id, :child_node_id, :ancestor_ids, :skip_update)
  end
  
  private
  
  def collection
    feature_name_id = params[:feature_name_id]
    search_results = FeatureNameRelation.search(params[:filter])
    search_results = search_results.where(['child_node_id = ?', feature_name_id]) if feature_name_id
    @collection = search_results.page(params[:page])
    
    ##object = FeatureName.find(params[:feature_name_id]) rescue nil # if we're locating a relation
    #conditions = params[:feature_name_id].nil? ? nil : ['child_node_id = ?', params[:feature_name_id]]
    #@collection = FeatureNameRelation.paginate(
    #  :all,
    #  :page=>params[:page],
    #  :conditions=>conditions
    #)
  end
  
  #
  # Needed to view (example)
  # /admin/feature_names/1054338673/feature_name_relations/554829466
  # This is called by ResourceController!
  #
  def parent_association
    ## Gotta find (as in another SQL query) it seperately, will get a recursive stack error elsewise
    
    # If we're viewing a FeatureNameRelation:
    return parent_object.parent_relations if params[:id].nil?
    
    # Gotta find it seperately (new query), will get a recursive stack error elsewise, rats!
    o = FeatureNameRelation.find(params[:id])
    parent_object.id == o.parent_node.id ? parent_object.child_relations : parent_object.parent_relations
  end
  
  def setup_for_new_relation
    object.child_node = parent_object # ResourceController can't seem to set this up?
    object.parent_node = FeatureName.find(params[:target_id])
  end
  
end