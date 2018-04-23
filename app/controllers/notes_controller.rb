class NotesController < ResourceController::Base
  belongs_to :description, :feature_geo_code, :feature_name, :feature_name_relation, :feature_relation, :time_unit
  
  index.wants.html { render(partial: 'notes/list', locals: { notes: collection.where(is_public: true) }) if request.xhr? }
end
