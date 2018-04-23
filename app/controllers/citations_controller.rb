class CitationsController < ResourceController::Base
  belongs_to :caption, :description, :feature_geo_code, :feature_name, :feature_name_relation, :feature_relation, :summary
  
  index.wants.html { render(partial: 'citations/list', locals: { citations: collection }) if request.xhr? }
end
