class Admin::PagesController < ApplicationController
  resource_controller
  belongs_to :citation
  
  create.wants.html { redirect_to polymorphic_url([:admin, object.citation.citable, object.citation]) }
  update.wants.html { redirect_to polymorphic_url([:admin, object.citation.citable, object.citation]) }
  destroy.wants.html { redirect_to polymorphic_url([:admin, object.citation.citable, object.citation]) }
  
  protected
  
  def parent_association
    parent_object.pages # ResourceController needs this for the parent association
  end
  
  def collection
    @collection = Page.where(:citation_id => parent_object.id).page(params[:page])
  end
  
  # Only allow a trusted parameter "white list" through.
  def page_params
    params.require(:page).permit(:volume, :start_page, :start_line, :end_page, :end_line, :citation_id)
  end
end