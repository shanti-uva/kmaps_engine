class CodesController < ApplicationController
  allow_unauthenticated_access
  before_action :find_feature
  
  def index
    @geo_codes = @feature.geo_codes
    respond_to do |format|
      format.xml
      format.json { render json: Hash.from_xml(render_to_string(action: 'index', formats: [:xml])) }
    end
  end
  
  private
  # This is tied to features
  def find_feature
    @feature = Feature.get_by_fid(params[:feature_id]) # Feature.find(params[:feature_id])
  end
end
