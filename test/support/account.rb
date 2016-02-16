require_relative 'acts_like_an_integer'

class Account < ActiveRecord::Base
  include PropertySets::Delegator
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
