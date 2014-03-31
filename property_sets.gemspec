lib = File.expand_path("../lib/", __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'property_sets/version'

Gem::Specification.new "property_sets", PropertySets::VERSION do |s|
  s.summary     = "Property sets for ActiveRecord."
  s.description = "This gem is an ActiveRecord extension which provides a convenient interface for managing per row properties."
  s.authors  = ["Morten Primdahl"]
  s.email    = 'primdahl@me.com'
  s.homepage = 'http://github.com/zendesk/property_sets'
  s.license  = 'Apache License Version 2.0'

  s.add_runtime_dependency("activesupport", ">= 2.3.14", "< 4.1")
  s.add_runtime_dependency("activerecord", ">= 2.3.14", "< 4.1")
  s.add_runtime_dependency("json")

  s.files = `git ls-files`.split("\n")
  s.license = "MIT"
end
