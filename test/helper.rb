require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/rg'
require 'mocha/setup'

require 'active_support'
require 'active_support/testing/setup_and_teardown'
require 'active_record'
require 'active_record/fixtures'

I18n.enforce_available_locales = false

require File.expand_path "../database", __FILE__

require 'property_sets'
require 'property_sets/delegator'
require_relative 'support/account'

class Minitest::Spec
  include ActiveSupport::Testing::SetupAndTeardown
  include ActiveRecord::TestFixtures

  if ActiveRecord::VERSION::STRING < '4.1.0'
    alias :method_name :__name__ if defined? :__name__
  else
    alias :method_name :name if defined? :name
  end

  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  $LOAD_PATH.unshift(self.fixture_path)

  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end
