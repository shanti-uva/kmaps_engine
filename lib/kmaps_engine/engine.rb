module KmapsEngine
  class Engine < ::Rails::Engine
    initializer :assets do |config|
      Rails.application.config.assets.paths << root.join('vendor', 'assets', 'images').to_s
      Rails.application.config.assets.precompile.concat(['kmaps_engine/kmaps_relations_tree.js'])
      Rails.application.config.assets.paths << root.join('vendor', 'assets', 'javascripts').to_s
      Rails.application.config.assets.precompile.concat(['sarvaka_kmaps/*'])
      Rails.application.config.assets.precompile.concat(['typeahead/*','kmaps_typeahead/*'])
      Rails.application.config.assets.precompile.concat(['kmaps_engine/admin.js', 'kmaps_engine/treescroll.js',
        'kmaps_engine/iframe.js', 'kmaps_engine/jquery.ajax.sortable.js',
        'kmaps_engine/admin.css', 'kmaps_engine/public.css', 'kmaps_engine/xml-books.css',
        'kmaps_engine/scholar.css', 'kmaps_engine/popular.css', 'kmaps_engine/main-image.js', 'kmaps_engine/gallery.css', 'gallery/default-skin.png','gallery/default-skin.svg','kmaps_tree/jquery.fancytree-all.min.js', 'kmaps_tree/kmapstree.css','kmaps_tree/icons.gif'])
      Rails.application.config.assets.precompile.concat(['collapsible_list/jquery.kmapsCollapsibleList.js'])
    end
    
    initializer :sweepers do |config|
      sweeper_folder = File.join('..', '..', 'app', 'sweepers')
      require_relative File.join(sweeper_folder, 'feature_sweeper')
      require_relative File.join(sweeper_folder, 'description_sweeper')
      require_relative File.join(sweeper_folder, 'caption_sweeper')
      require_relative File.join(sweeper_folder, 'summary_sweeper')
      require_relative File.join(sweeper_folder, 'feature_geo_code_sweeper')
    end
    
    initializer :loader do |config|
      require 'active_record/kmaps_engine/extension'
      require 'kmaps_engine/array_ext'
      require 'kmaps_engine/import/importation.rb'
      require 'kmaps_engine/extensions/user_model.rb'
      require 'kmaps_engine/resource_object_authentication.rb'
      
      ActiveRecord::Base.send :include, ActiveRecord::KmapsEngine::Extension
      Array.send :include, KmapsEngine::ArrayExtension
      AuthenticatedSystem::User.send :include, KmapsEngine::Extension::UserModel
      
      Sprockets::Context.send :include, Rails.application.routes.url_helpers
    end
  end
end
