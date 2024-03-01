Rails.application.config.assets.precompile.concat(['kmaps_engine/essays_admin.js'])

Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'images').to_s
Rails.application.config.assets.precompile.concat(['kmaps_engine/kmaps_relations_tree.js'])
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'javascripts').to_s
Rails.application.config.assets.precompile.concat(['typeahead/*','kmaps_typeahead/*'])
Rails.application.config.assets.precompile.concat(['kmaps_engine/admin.js', 'kmaps_engine/treescroll.js',
  'kmaps_engine/iframe.js', 'kmaps_engine/jquery.ajax.sortable.js', 'kmaps_engine/admin.css',
  'kmaps_engine/scholar.css', 'kmaps_engine/popular.css', 'kmaps_engine/main-image.js', 'gallery/default-skin.png',
  'gallery/default-skin.svg','kmaps_tree/jquery.fancytree-all.min.js','kmaps_tree/icons.gif'])
Rails.application.config.assets.precompile.concat(['sarvaka_kmaps/*', 'collapsible_list/kmaps_collapsible_list.css', 'kmaps_tree/kmapstree.css', 'kmaps_engine/xml-books.css', 'kmaps_engine/gallery.css'])
Rails.application.config.assets.precompile.concat(['collapsible_list/jquery.kmapsCollapsibleList.js'])
Rails.application.config.assets.precompile.concat(['kmaps_engine/descriptions_admin_accordion.js'])
