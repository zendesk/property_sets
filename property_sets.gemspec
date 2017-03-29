require './lib/property_sets/version'

Gem::Specification.new "property_sets", PropertySets::VERSION do |s|
  s.summary     = "Property sets for ActiveRecord."
  s.description = "This gem is an ActiveRecord extension which provides a convenient interface for managing per row properties."
  s.authors  = ["Morten Primdahl"]
  s.email    = 'primdahl@me.com'
  s.homepage = 'http://github.com/zendesk/property_sets'
  s.license  = 'Apache License Version 2.0'

  s.add_runtime_dependency("activerecord", ">= 3.2", "< 5.2")
  s.add_runtime_dependency("json")

  s.add_development_dependency("bump")
  s.add_development_dependency("rake")
  s.add_development_dependency('actionpack')
  s.add_development_dependency('rspec')
  s.add_development_dependency('wwtd', '>= 0.5.3')
  s.add_development_dependency('byebug')

  s.files = `git ls-files lib`.split("\n")
  s.license = "MIT"
end
