ActiveSupport.on_load(:active_record) do
  require_dependency 'kmaps_engine/active_record/extensions'
  include KmapsEngine::ActiveRecord::Extensions
end

ActiveSupport.on_load(:authenticated_system_user) do
  require_dependency 'kmaps_engine/user_extensions'  # needed even under app/models/concerns
  include KmapsEngine::UserExtensions
end