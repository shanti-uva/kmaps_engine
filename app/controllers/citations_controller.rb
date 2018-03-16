class CitationsController < ResourceController::Base
  belongs_to :caption, :description, :feature_geo_code, :feature_name, :feature_name_relation, :feature_relation, :summary
  
  def index
    unless parent_object.nil?
      @citations = parent_object.citations
      render :partial => '/citations/list'
    end
  end
end
