class FeatureNamesController < ApplicationController
  allow_unauthenticated_access
  before_action :find_feature
  
  def show
    @name = FeatureName.find(params[:id])
    respond_to do |format|
      format.xml
      format.json { render json: Hash.from_xml(render_to_string(action: 'show', formats: [:xml])) }
    end
  end
  
  def index
    if @feature.nil?
      @name_count = 1 #FeatureName.select('feature_id, COUNT(DISTINCT id) as count').group('feature_id').order('count DESC').first.count.to_i
      @citation_count = 1 #FeatureName.joins(:citations).select('feature_names.id, COUNT(DISTINCT citations.id) as count').group('feature_names.id').order('count DESC').first.count.to_i
      @features = [] #FeatureName.select('feature_id').uniq.order('feature_id').includes(:feature => :names).references(:feature => :names).collect(&:feature)
      #@view = View.get_by_code(default_view_code)
      respond_to do |format|
        format.csv
        format.xml
        format.json { render json: Hash.from_xml(render_to_string(action: 'index', formats: [:xml])) }
      end
    else
      respond_to do |format|
        format.csv { render :action => 'index_by_feature' }
        format.xml do
          @names = @feature.names.roots.order('position')
          render action: 'index_by_feature', formats: [:xml]
        end
        format.json do
          @names = @feature.names.roots.order('position')
          render json: Hash.from_xml(render_to_string(action: 'index_by_feature', formats: [:xml]))
        end
      end
    end
  end
  
  private
  # This is tied to features
  def find_feature
    feature_id = params[:feature_id]
    @feature = feature_id.nil? ? nil : Feature.get_by_fid(feature_id) # Feature.find(params[:feature_id])
  end
end
