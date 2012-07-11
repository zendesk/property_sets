Gem::Specification.new "property_sets", "0.7.2" do |s|
  s.summary     = "Property sets for ActiveRecord."
  s.description = "This gem is an ActiveRecord extension which provides a convenient interface for managing per row properties."
  s.authors  = ["Morten Primdahl"]
  s.email    = 'primdahl@me.com'
  s.homepage = 'http://github.com/morten/property_sets'

  s.add_runtime_dependency("activesupport", ">= 2.3.14", "< 3.3")
  s.add_runtime_dependency("activerecord", ">= 2.3.14", "< 3.3")
  s.add_runtime_dependency("actionpack", ">= 2.3.14", "< 3.3")
  s.add_runtime_dependency("json")

  s.add_development_dependency('rake')
  s.add_development_dependency('bundler')
  s.add_development_dependency('shoulda')
  s.add_development_dependency('mocha')
  s.add_development_dependency('appraisal')

  s.files = `git ls-files`.split("\n")
  s.license = "MIT"
end
