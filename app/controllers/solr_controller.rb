class SolrController < ApplicationController
  allow_unauthenticated_access
  caches_page :show
  
  #
  #
  #
  def show
    feature = Feature.get_by_fid(params[:id])
    respond_to do |format|
      format.json { render json: JSON.generate(feature.document_for_rsolr) }
    end
  end
end
