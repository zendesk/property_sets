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

#$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'property_sets'
require 'property_sets/delegator'

class Minitest::Spec
  include ActiveSupport::Testing::SetupAndTeardown
  include ActiveRecord::TestFixtures

  case
  when ActiveRecord::VERSION::MAJOR == 3
    alias :method_name :__name__ if defined? :__name__
  when ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR < 1
    alias :method_name :__name__ if defined? :__name__
  when ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR >= 1
    alias :method_name :name if defined? :name
  end

  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  $LOAD_PATH.unshift(self.fixture_path)

  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
end


class ActsLikeAnInteger
  def to_i
    123
  end
end

class Account < ActiveRecord::Base
  include PropertySets::Delegator
  attr_accessor :proc_value
  delegate_to_property_set :settings, :old => :hep

  property_set :settings do
    property :foo
    property :bar
    property :baz
    property :hep, :default   => 'skep'
    property :pro, :protected => true
    property :bool_true, :type => :boolean, :default => true
    property :bool_false, :type => :boolean, :default => false
    property :bool_nil, :type => :boolean, :default => nil
    property :with_proc, :type => :boolean, :default => ->(account) { account.proc_value }
  end

  property_set :settings do
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
