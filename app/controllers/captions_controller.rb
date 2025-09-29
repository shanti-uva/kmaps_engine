class CaptionsController < ApplicationController
  allow_unauthenticated_access
  before_action :find_feature
  
  def show
    @caption = Caption.find(params[:id])
    respond_to do |format|
      format.xml  { render xml: @caption   }
      format.json { render json:  @caption } #Hash.from_xml(render_to_string(action: 'show', format: 'xml')) }
    end
  end

  def index
    @captions = @feature.captions
    respond_to do |format|
      format.xml  { render xml: @captions  }
      format.json { render json: @captions } #Hash.from_xml(render_to_string(action: 'index', format: 'xml')) }
    end
  end
  
  private
  # This is tied to features
  def find_feature
    @feature = Feature.get_by_fid(params[:feature_id]) # Feature.find(params[:feature_id])
  end
end
