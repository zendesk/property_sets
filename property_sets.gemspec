## This is the rakegem gemspec template. Make sure you read and understand
## all of the comments. Some sections require modification, and others can
## be deleted if you don't need them. Once you understand the contents of
## this file, feel free to delete any comments that begin with two hash marks.
## You can find comprehensive Gem::Specification documentation, at
## http://docs.rubygems.org/read/chapter/20
Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.8.15'

  ## Leave these as is they will be modified for you by the rake gemspec task.
  ## If your rubyforge_project name is different, then edit it and comment out
  ## the sub! line in the Rakefile
  s.name              = 'property_sets'
  s.version           = '0.6.0'
  s.date              = '2012-03-22'
  s.rubyforge_project = 'property_sets'

  ## Make sure your summary is short. The description may be as long
  ## as you like.
  s.summary     = "Property sets for ActiveRecord."
  s.description = "This gem is an ActiveRecord extension which provides a convenient interface for managing per row properties."

  ## List the primary authors. If there are a bunch of authors, it's probably
  ## better to set the email to an email list or something. If you don't have
  ## a custom homepage, consider using your GitHub URL or the like.
  s.authors  = ["Morten Primdahl"]
  s.email    = 'primdahl@me.com'
  s.homepage = 'http://github.com/morten/property_sets'

  ## This gets added to the $LOAD_PATH so that 'lib/NAME.rb' can be required as
  ## require 'NAME.rb' or'/lib/NAME/file.rb' can be as require 'NAME/file.rb'
  s.require_paths = %w[lib]

  ## This sections is only necessary if you have C extensions.
  # s.require_paths << 'ext'
  # s.extensions = %w[ext/extconf.rb]

  ## If your gem includes any executables, list them here.
  # s.executables = ["name"]

  ## Specify any RDoc options here. You'll want to add your README and
  ## LICENSE files to the extra_rdoc_files list.
  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = %w[README.md LICENSE.txt]

  ## List your runtime dependencies here. Runtime dependencies are those
  ## that are needed for an end user to actually USE your code.
  s.add_runtime_dependency("activesupport", ">= 2.3.14", "< 3.3")
  s.add_runtime_dependency("activerecord", ">= 2.3.14", "< 3.3")
  s.add_runtime_dependency("actionpack", ">= 2.3.14", "< 3.3")
  s.add_runtime_dependency("json")

  ## List your development dependencies here. Development dependencies are
  ## those that are only needed during development
  s.add_development_dependency('rake')
  s.add_development_dependency('bundler')
  s.add_development_dependency('shoulda')
  s.add_development_dependency('mocha')
  s.add_development_dependency("appraisal")

  ## Leave this section as-is. It will be automatically generated from the
  ## contents of your Git repository via the gemspec task. DO NOT REMOVE
  ## THE MANIFEST COMMENTS, they are used as delimiters by the task.
  # = MANIFEST =
  s.files = %w[
    Appraisals
    Gemfile
    LICENSE.txt
    README.md
    Rakefile
    gemfiles/rails2.3.gemfile
    gemfiles/rails2.3.gemfile.lock
    gemfiles/rails3.2.gemfile
    gemfiles/rails3.2.gemfile.lock
    lib/property_sets.rb
    lib/property_sets/action_view_extension.rb
    lib/property_sets/active_record_extension.rb
    lib/property_sets/casting.rb
    lib/property_sets/property_set_model.rb
    property_sets.gemspec
    test/fixtures/account_settings.yml
    test/fixtures/account_texts.yml
    test/fixtures/accounts.yml
    test/helper.rb
    test/schema.rb
    test/test_casting.rb
    test/test_property_sets.rb
    test/test_view_extensions.rb
  ]
  # = MANIFEST =

  ## Test files will be grabbed from the file list. Make sure the path glob
  ## matches what you actually use.
  s.test_files = s.files.select { |path| path =~ /^test\/test_.*\.rb/ }
end
