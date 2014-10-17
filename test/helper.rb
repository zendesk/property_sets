require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/rg'
require 'mocha/setup'

require 'active_support'
require 'active_record'
require 'active_record/fixtures'

if ActiveRecord::VERSION::MAJOR < 4
  ActiveRecord::Base.mass_assignment_sanitizer = :strict
end

if ActiveRecord::VERSION::MAJOR == 4
  require 'protected_attributes'
end
ActiveRecord::Base.attr_accessible

I18n.enforce_available_locales = false

require File.expand_path "../database", __FILE__

#$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'property_sets'
require 'property_sets/delegator'

Minitest::Unit::TestCase.class_eval do
  if ActiveRecord::VERSION::MAJOR == 3
    def self.setup(method)
      include Module.new { define_method(:setup) { super(); send(method) } }
    end

    def self.teardown(method)
      include Module.new { define_method(:teardown) { send(method); super() } }
    end
  end

  include ActiveRecord::TestFixtures

  def create_fixtures(*table_names)
    if block_given?
      Fixtures.create_fixtures(Minitest::Unit::TestCase.fixture_path, table_names) { yield }
    else
      Fixtures.create_fixtures(Minitest::Unit::TestCase.fixture_path, table_names)
    end
  end

  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end

Minitest::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
$LOAD_PATH.unshift(Minitest::Unit::TestCase.fixture_path)

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
    property :bool_true, :type => :boolean, :default => true
    property :bool_false, :type => :boolean, :default => false
    property :bool_nil, :type => :boolean, :default => nil
    property :bool_nil2, :type => :boolean
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
