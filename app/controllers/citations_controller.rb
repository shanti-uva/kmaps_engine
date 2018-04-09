class CitationsController < ResourceController::Base
  belongs_to :caption, :description, :feature_geo_code, :feature_name, :feature_name_relation, :feature_relation, :summary
  
  index.wants.html do
    #TODO: if request.xhr? fallback for non js call
    parent_object
    render partial: 'citations/list', locals: { citations: collection }
  end
end
