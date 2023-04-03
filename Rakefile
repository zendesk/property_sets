require 'bundler/gem_tasks'
require 'bump/tasks'
require 'rspec/core/rake_task'

task default: :spec

# Pushing to rubygems is handled by a github workflow
ENV["gem_push"] = "false"

RSpec::Core::RakeTask.new(:spec)
