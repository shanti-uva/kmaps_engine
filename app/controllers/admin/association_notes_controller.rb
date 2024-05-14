class Admin::AssociationNotesController < AclController
  include KmapsEngine::ResourceObjectAuthentication
  resource_controller
  
  belongs_to :feature
  before_action :collection
  before_action :validate_association_type, :only => [:new]

  edit.before {@authors = AuthenticatedSystem::Person.order('fullname') }
  new_action.before do
    object.association_type = params[:association_type]
    object.notable_type = parent_object.class.name
  end

  create.wants.html do
    if object.notable.class == Feature
      redirect_to admin_feature_url(object.notable.fid, section: object.association_type.pluralize.downcase)
    else
      redirect_to polymorphic_url([:admin, object.notable], section: object.association_type.pluralize.downcase)
    end
  end

  update.wants.html do
    if object.notable.class == Feature
      redirect_to admin_feature_url(object.notable.fid, section: object.association_type.pluralize.downcase)
    else
      redirect_to polymorphic_url([:admin, object.notable], section: object.association_type.pluralize.downcase)
    end
  end

  destroy.wants.html do
    if object.notable.class == Feature
      redirect_to admin_feature_url(object.notable.fid, section: object.association_type.pluralize.downcase)
    else
      redirect_to polymorphic_url([:admin, object.notable], section: object.association_type.pluralize.downcase)
    end
  end
  
  def initialize
    super
    @guest_perms = []
  end
  
  # renders add_author.js.erb
  def add_author
    @authors = AuthenticatedSystem::Person.order('fullname')
  end
  
  protected
  
  def parent_association
    parent_object.association_notes # ResourceController needs this for the parent association
  end
  
  def collection
    search_results = AssociationNote.search(params[:filter])
    search_results = search_results.where(['notable_id = ? AND notable_type = ?', parent_object.id, parent_object.class.to_s]) if parent?
    @collection = search_results.page(params[:page])
  end
  
  def validate_association_type
    render :text => "Sorry, an association type hasn't been specified." and return if (
      (object.nil? && params[:association_type].blank?) ||
      (!object.nil? && object.association_type.blank?))
  end
  
  # Only allow a trusted parameter "white list" through.
  def association_note_params
    params.require(:association_note).permit(:association_type, :notable_type, :notable_id, :custom_note_title, :note_title_id, :content, :is_public, author_ids: [])
  end
end
