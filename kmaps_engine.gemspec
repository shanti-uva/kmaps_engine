$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "kmaps_engine/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "kmaps_engine"
  s.version     = KmapsEngine::VERSION
  s.authors     = ["Andres Montano"]
  s.email       = ["amontano@virginia.edu"]
  s.homepage    = "http://subjects.kmaps.virginia.edu"
  s.summary     = "This engine provides the core code for creating apps that organize information in a hierarchical fasion we call a knowledge map."
  s.description = "This engine provides the core code for creating apps that organize information in a hierarchical fasion we call a knowledge map."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]
  
  # Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
  s.add_dependency 'rails', '4.1.16'

  # Use postgresql as the database for Active Record
  s.add_dependency 'pg', '~> 0.15'
  
  # Use Uglifier as compressor for JavaScript assets
  s.add_dependency 'uglifier', '>= 1.3.0'

  # Use CoffeeScript for .js.coffee assets and views
  s.add_dependency 'coffee-rails', '~> 4.1.0'
  
  # Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
  s.add_dependency 'turbolinks'

  # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
  s.add_dependency 'jbuilder', '~> 2.0'
  
  s.add_dependency 'hpricot' #, '>= 0.8.6'
  s.add_dependency 'will_paginate' #, '~> 3.0'

  s.add_dependency 'memcache-client'
  s.add_dependency 'exception_notification'
  s.add_dependency 'annotate'
  #gem 'system_timer'
  #gem 'cached_resource'
end
