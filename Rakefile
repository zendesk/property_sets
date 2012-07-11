require 'bundler/gem_tasks'
require 'appraisal'

require 'rake/testtask'
Rake::TestTask.new do |test|
  test.libs << 'lib'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default do
  sh "bundle exec rake appraisal:install && bundle exec rake appraisal test"
end
