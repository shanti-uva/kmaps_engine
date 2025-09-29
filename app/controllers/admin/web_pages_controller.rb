class Admin::WebPagesController < ApplicationController
  resource_controller
  belongs_to :citation
  
  create.wants.html { redirect_to polymorphic_url([:admin, object.citation.citable, object.citation]) }
  update.wants.html { redirect_to polymorphic_url([:admin, object.citation.citable, object.citation]) }
  destroy.wants.html { redirect_to polymorphic_url([:admin, object.citation.citable, object.citation]) }
  
  protected
  
  def parent_association
    parent_object.web_pages # ResourceController needs this for the parent association
  end
  
  def collection
    @collection = WebPage.where(:citation_id => parent_object.id).page(params[:page])
  end
  
  # Only allow a trusted parameter "white list" through.
  def web_page_params
    params.require(:web_page).permit(:path, :title, :citation_id)
  end
end