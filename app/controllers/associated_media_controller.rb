class AssociatedMediaController < ApplicationController
  allow_unauthenticated_access
  before_action :find_feature
  skip_before_action :find_feature, only: :show

  # GET /topics/1/pictures
  def pictures
    # @media = MmsIntegration::Picture.search_by_place(@feature.fid, page: params[:page] || 1, per_page: MmsIntegration::Picture::PER_PAGE )
    @media = MmsIntegration::Picture.search_by_kmapid(@feature.uid, page: params[:page] || 1, per_page: MmsIntegration::Picture::PER_PAGE )
    @title = ts(:in, what: MmsIntegration::Picture.human_name(count: :many).titleize, where: @feature.prioritized_name(current_view).name)
    render_media
  end
  
  # GET /topics/1/videos
  def videos
    # @media = MmsIntegration::Place.paginated_media(@feature.fid, 'videos', page: params[:page], :per_page => params[:per_page])
    @media = MmsIntegration::Video.search_by_kmapid(@feature.uid, page: params[:page] || 1, per_page: MmsIntegration::Video::PER_PAGE )
    @title = ts(:in, :what => MmsIntegration::Video.human_name(:count => :many).titleize, :where => @feature.prioritized_name(current_view).name)
    render_media
  end
  
  # GET /topics/1/documents
  def documents
    # @media = MmsIntegration::Place.paginated_media(@feature.fid, 'documents', page: params[:page], :per_page => params[:per_page])
    @media = MmsIntegration::Document.search_by_kmapid(@feature.uid, page: params[:page] || 1, per_page: MmsIntegration::Document::PER_PAGE )
    @title = ts(:in, :what => MmsIntegration::Document.human_name(:count => :many).titleize, :where => @feature.prioritized_name(current_view).name)
    render_media
  end
  
  def show
    @url = MmsIntegration::Medium.get_url("#{params[:id]}/external")
    respond_to do |format|
      format.js
    end
  end

  private
  
  def render_media
    respond_to do |format|
      format.js   { render 'index' }
      format.html { render 'index' }
    end
  end
  
  def find_feature
    feature_id = params[:id]
    @feature = feature_id.nil? ? nil : Feature.get_by_fid(feature_id) # Feature.find(params[:feature_id])
  end
end