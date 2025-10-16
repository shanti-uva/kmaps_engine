module KmapsEngine
  class Engine < ::Rails::Engine
    initializer :loader do |config|
      require 'kmaps_engine/array_ext'
      require 'kmaps_engine/import/importation.rb'
      
      ::Array.include KmapsEngine::ArrayExtension
      Sprockets::Context.include Rails.application.routes.url_helpers
    end

    config.generators do |g|
      g.test_framework :rspec
      g.assets false
      g.helper false
    end
    
    config.to_prepare do
      require_dependency 'authenticated_system/user'
      require_dependency 'kmaps_engine/user_extensions'  # needed even under app/models/concerns
      AuthenticatedSystem::User.include KmapsEngine::UserExtensions
    end
  end
end
