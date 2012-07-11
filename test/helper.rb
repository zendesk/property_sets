require 'rubygems'
require 'bundler'
Bundler.setup
require 'active_support'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'
require 'shoulda'

require File.expand_path "../database", __FILE__

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'property_sets'

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Test::Unit::TestCase.fixture_path, table_names)
    end
  end

  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end

ActiveSupport::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(ActiveSupport::TestCase.fixture_path)

class Account < ActiveRecord::Base
  property_set :settings do
    property :foo
    property :bar
    property :baz
    property :hep, :default   => 'skep'
    property :pro, :protected => true
  end

  property_set :texts do
    property :foo
    property :bar
  end
  accepts_nested_attributes_for :texts

  property_set :validations do
    property :validated
    property :regular

    validates_format_of :value, :with => /\d+/, :message => "BEEP", :if => lambda { |r| r.name.to_sym == :validated }
  end

  property_set :typed_data do
    property :string_prop, :type => :string
    property :datetime_prop, :type => :datetime
    property :float_prop, :type => :float
    property :int_prop, :type => :integer
    property :serialized_prop, :type => :serialized
  end
end
