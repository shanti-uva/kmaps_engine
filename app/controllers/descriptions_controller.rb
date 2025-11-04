class DescriptionsController < ApplicationController
  allow_unauthenticated_access
  before_action :find_feature
 
  def contract
    d = Description.find(params[:id])
    render :partial => '/descriptions/contracted', :locals => {:feature => @feature, :d => d}
  end
  
  # renders expand.js.erb
  def expand
    @d = Description.find(params[:id])
    @description =  Description.find(params[:id])    
  end
  
  def index
    if @feature.nil?
      @descriptions = Description.all
      @view = View.get_by_code(default_view_code)
      respond_to do |format|
        format.html { redirect_to features_url }
        format.xml
        format.json { render json: Hash.from_xml(render_to_string(action: 'index', formats: [:xml])), callback: params[:callback] }
      end
    else
      @descriptions = @feature.descriptions
      respond_to do |format|
        format.xml
        format.json { render json: Hash.from_xml(render_to_string(action: 'index', formats: [:xml])), callback: params[:callback] }
      end
    end
  end
  
  def show
    @description = Description.find(params[:id])
    if @feature.nil?
      @feature = @description.feature
      @view = View.get_by_code(default_view_code)
    end
    @tab_options = {:entity => @feature}
    @current_tab_id = :descriptions
    respond_to do |format|
      format.html
      format.xml
      format.js
      format.json { render json: Hash.from_xml(render_to_string(action: 'show', formats: [:xml])), callback: params[:callback] }
    end
  end

  private
  # This is tied to features
  def find_feature
    feature_id = params[:feature_id]
    @feature = feature_id.nil? ? nil : Feature.get_by_fid(feature_id) # Feature.find(params[:feature_id])
  end
end
