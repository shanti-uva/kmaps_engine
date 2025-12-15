class CitationsController < ResourceController::Base
  allow_unauthenticated_access
  
  belongs_to :descriptions, :feature_geo_code, :feature_name, :feature_name_relation, :feature_relation
  
  index.wants.html { render(partial: 'citations/list', locals: { citations: collection }) if request.xhr? }
end
