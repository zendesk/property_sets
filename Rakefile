require "bundler/setup"
require "bundler/gem_tasks"
require "bump/tasks"
require "rspec/core/rake_task"
require "standard/rake"

task default: [:spec, :standard]

RSpec::Core::RakeTask.new(:spec)
