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
  
  # Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
  s.add_dependency 'rails', '~> 7.1.0' #, '~> 5.2.3'
  # Use postgresql as the database for Active Record
  s.add_dependency 'pg'
  # Use Puma as the app server
  s.add_dependency 'puma'
  # Use Uglifier as compressor for JavaScript assets
  # s.add_dependency 'uglifier', '~> 4.1', '>= 4.1.20'
  # See https://github.com/rails/execjs#readme for more supported runtimes
  # gem 'therubyracer', platforms: :ruby

  s.add_dependency 'delayed_job_active_record'

  # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
  s.add_dependency 'jbuilder'
  # Reduces boot times through caching; required in config/boot.rb
  s.add_dependency 'bootsnap' #, require: false
  
  # Use Redis adapter to run Action Cable in production
  # gem 'redis', '~> 3.0'
  # Use ActiveModel has_secure_password
  # gem 'bcrypt', '~> 3.1.7'

  # Use Capistrano for deployment
  # gem 'capistrano-rails', group: :development
  
  s.add_dependency 'hpricot' #, '>= 0.8.6'
  s.add_dependency 'will_paginate' #, '~> 3.0'

  s.add_dependency 'memcache-client'
  s.add_dependency 'exception_notification'
  s.add_dependency 'annotate'
  #gem 'system_timer'
  #gem 'cached_resource'

  #Testing dependencies
  s.add_development_dependency 'rspec-rails'
  s.test_files = Dir["spec/**/*"]
end
