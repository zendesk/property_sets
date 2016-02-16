require 'bundler/setup'
require 'bundler/gem_tasks'
require 'bump/tasks'
require 'wwtd/tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => "wwtd:local"
