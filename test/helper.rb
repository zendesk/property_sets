require 'rubygems'
require 'active_support'
require 'test/unit'
require 'active_record'
require 'active_record/fixtures'
require 'shoulda'
require 'ruby-debug'

ActiveRecord::Base.configurations = YAML::load(IO.read(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection('test')
ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/test.log")

load(File.dirname(__FILE__) + "/schema.rb")

$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.dirname(__FILE__)+'/../lib/property_sets'

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
end
