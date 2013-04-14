$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "cultural_network/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "cultural_network"
  s.version     = CulturalNetwork::VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of CulturalNetwork."
  s.description = "TODO: Description of CulturalNetwork."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"
  # s.add_dependency "jquery-rails"

  s.add_development_dependency "pg"
end
