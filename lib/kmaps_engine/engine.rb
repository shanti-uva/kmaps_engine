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
      Rails.application.config.assets.precompile.concat(['collapsible_list/jquery.kmapsCollapsibleList.js','collapsible_list/kmaps_collapsible_list.css.scss'])
    end
    
    initializer :sweepers do |config|
      #sweeper_folder = File.join('..', '..', 'app', 'sweepers')
      #require_relative File.join(sweeper_folder, 'feature_sweeper')
      #require_relative File.join(sweeper_folder, 'feature_relation_sweeper')
      #require_relative File.join(sweeper_folder, 'summary_sweeper')
      observers = [FeatureSweeper, FeatureRelationSweeper, SummarySweeper]
      Rails.application.config.active_record.observers ||= []
      Rails.application.config.active_record.observers += observers
      observers.each { |o| o.instance }
    end
    
    initializer :loader do |config|
      require 'active_record/kmaps_engine/extension'
      require 'kmaps_engine/array_ext'
      require 'kmaps_engine/import/importation.rb'
      require 'kmaps_engine/extensions/user_model.rb'
      
      ActiveRecord::Base.send :include, ActiveRecord::KmapsEngine::Extension
      Array.send :include, KmapsEngine::ArrayExtension
      AuthenticatedSystem::User.send :include, KmapsEngine::Extension::UserModel
      
      Sprockets::Context.send :include, Rails.application.routes.url_helpers
    end

    config.generators do |g|
      g.test_framework :rspec
      g.assets false
      g.helper false
    end

  end
end
