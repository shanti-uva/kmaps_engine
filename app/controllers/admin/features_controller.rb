class Admin::FeaturesController < AclController
  include KmapsEngine::ResourceObjectAuthentication
  resource_controller
  
  cache_sweeper :feature_sweeper, :only => [:update, :destroy]

  def initialize
    super
    @guest_perms = []
  end

  before_action :collection, only: :locate_for_relation
  
  new_action.before do
    object.is_public = true
    parent_id = params[:parent_id]
    @parent = parent_id.blank? ? nil : Feature.get_by_fid(parent_id)
    if !@parent.nil?
      @perspectives = @parent.affiliations_by_user(current_user, descendants: true).collect(&:perspective)
      @perspectives = Perspective.order(:name) if @perspectives.include?(nil) || current_user.admin?
      @name = FeatureName.new(language: Language.get_by_code('eng'), writing_system: WritingSystem.get_by_code('latin'), is_primary_for_romanization: true)
      @relation = FeatureRelation.new(parent_node: @parent, perspective: current_perspective, feature_relation_type: FeatureRelationType.get_by_code(default_relation_type_code) )
    end
  end
  
  create.before do
    object.fid = Feature.generate_pid
    object.skip_update = true
  end
  
  create.after do |r|
    if !object.id.nil?
      object.names.create(feature_name_params.merge(skip_update: true))
      relation = object.all_parent_relations.create(feature_relation_params)
      affiliations = object.affiliations
      relation.parent_node.affiliations.where(descendants: true).each { |a| affiliations.create(perspective_id: a.perspective&.id, collection_id: a.collection.id, descendants: true) }
    else
      object.fid = Feature.generate_pid
      object.is_public = true
      parent_id = feature_relation_params[:parent_node_id]
      @parent = parent_id.blank? ? nil : Feature.find(parent_id)
      if !@parent.nil?
        @perspectives = @parent.affiliations_by_user(current_user, descendants: true).collect(&:perspective)
        @perspectives = Perspective.order(:name) if @perspectives.include? nil
        @name = FeatureName.new(feature_name_params)
        @relation = FeatureRelation.new(feature_relation_params)
      end
    end
  end
  
  update.before { update_primary_description }

  new_action.wants.html { render('admin/features/select_ancestor') if @parent.nil?  }
  create.wants.html  { redirect_to admin_feature_url(object.fid) }
  update.wants.html  { redirect_to admin_feature_url(object.fid) }
  destroy.before { @parent = object.closest_parent_by_perspective(current_perspective) }
  destroy.wants.html { redirect_to @parent.nil? ? admin_root_url : admin_feature_url(@parent.fid) }
  
  def locate_for_relation
    @locating_relation=true
    # Remove the Feature that is currently looking for a relation
    # (shouldn't be possible to relate to itself)
    @collection = @collection.where.not(is_public: 0, fid: object.fid)
    render action: :index
  end
  
  def set_primary_description
    @feature = Feature.get_by_fid(params[:id])
    #render :action => 'primary_description_set'
  end
  
  def clone
    redirect_to admin_feature_url(Feature.get_by_fid(params[:id]).clone_with_names.fid)
  end
  
  protected
  
  # Only allow a trusted parameter "white list" through.
  def feature_params
    params.require(:feature).permit(:is_public, :fid, :is_blank, :ancestor_ids, :skip_update, names: [:name, :feature_name_type_id, :language_id, :writing_system_id, :etymology, :feature_name, :is_primary_for_romanization, :ancestor_ids, :skip_update, :feature_id, :position], all_parent_relations: [:perspective_id, :parent_node_id, :child_node_id, :feature_relation_type_id, :ancestor_ids, :skip_update])
  end
  
  # Only allow a trusted parameter "white list" through.
  def feature_name_params
    params.require(:feature_name).permit(:name, :feature_name_type_id, :language_id, :writing_system_id, :etymology, :feature_name, :is_primary_for_romanization, :ancestor_ids, :skip_update, :feature_id, :position)
  end
  
  # Only allow a trusted parameter "white list" through.
  def feature_relation_params
    params.require(:feature_relation).permit(:perspective_id, :parent_node_id, :child_node_id, :feature_relation_type_id, :ancestor_ids, :skip_update)
  end
  
  private
  def object
    @object ||= Feature.get_by_fid(params[:id])
  end
  
  def collection
    filter = params[:filter]
    context_id = params[:context_id]
    page = params[:page]
    unless context_id.blank?
      @context_feature, @collection = Feature.contextual_search(context_id, filter)
    else
      @collection = Feature.search(Search.new(filter: filter, context_id: context_id, scope: 'name'))
    end
    @collection = @collection.joins(:affiliations).where(affiliations: {collection_id: current_user.collections.collect(&:id)}) if !current_user.admin?
    @collection = @collection.page(page)
  end
  
  def update_primary_description
    if !params[:primary].nil? 
      feat = Feature.find(params[:id])
      primary_desc = Description.find(params[:primary])
      feat.descriptions.update_all("is_primary = false")
      feat.descriptions.update_all("is_primary = true","id=#{primary_desc.id}")
    end
  end
  
  ActiveSupport.run_load_hooks(:admin_features_controller, Admin::FeaturesController)
end
