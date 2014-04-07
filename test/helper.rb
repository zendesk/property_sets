require 'rubygems'
require 'bundler'
Bundler.setup

require 'test/unit'

begin
  require 'mocha/setup' # Rails 2
rescue LoadError
  require 'mocha'
end

require 'active_support'
require 'active_support/core_ext'
require 'active_record'
require 'active_record/fixtures'
require 'shoulda'

if ActiveRecord::VERSION::MAJOR > 2
  if ActiveRecord::VERSION::MINOR > 1
    ActiveRecord::Base.mass_assignment_sanitizer = :strict
  end
  if ActiveRecord::VERSION::MAJOR == 4
    require 'protected_attributes'
  end
  ActiveRecord::Base.attr_accessible
end

I18n.enforce_available_locales = false if ActiveRecord::VERSION::MAJOR > 2

require File.expand_path "../database", __FILE__

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'property_sets'
require 'property_sets/delegator'

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

class ActsLikeAnInteger
  def to_i
    123
  end
end

class Account < ActiveRecord::Base
  include PropertySets::Delegator
  delegate_to_property_set :settings, :old => :hep

  attr_accessible :name
  attr_accessible :texts_attributes

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
    property :default_prop, :type => :integer, :default => ActsLikeAnInteger.new
    property :serialized_prop_with_default, :type => :serialized, :default => "[]"
  end
end
