require 'bundler/setup'
require 'bundler/gem_tasks'
require 'bump/tasks'
require 'wwtd/tasks'

require 'rake/testtask'
Rake::TestTask.new do |test|
  test.verbose = true
end

task :default => "wwtd:local"
