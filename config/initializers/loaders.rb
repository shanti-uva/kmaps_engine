ActiveSupport.on_load(:active_record) do
  require_dependency 'kmaps_engine/active_record/extensions'
  include KmapsEngine::ActiveRecord::Extensions
end