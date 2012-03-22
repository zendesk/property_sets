require File.expand_path(File.dirname(__FILE__) + '/helper')
require 'property_sets/casting'

class TestCasting < ActiveSupport::TestCase

  context "Casting#read" do
    should "return nil when given value nil regardless of type" do
      assert_equal nil, PropertySets::Casting.read(:string, nil)
      assert_equal nil, PropertySets::Casting.read(:hello, nil)
    end

    should "deserialize properly" do
      assert_equal [1,2,3], PropertySets::Casting.read(:serialized, "[1, 2, 3]")
    end
  end

  context "Casting#write" do
    should "return nil when given value nil regardless of type" do
      assert_equal nil, PropertySets::Casting.write(:string, nil)
      assert_equal nil, PropertySets::Casting.write(:hello, nil)
    end

    should "convert time instances to UTC" do
      time = Time.now.in_time_zone("CET")
      assert PropertySets::Casting.write(:datetime, time) =~ /UTC$/
    end

    should "convert integers to strings" do
      assert_equal "123", PropertySets::Casting.write(:integer, 123)
    end

    should "serialize data marked as :serialize to json" do
      assert_equal "[123]", PropertySets::Casting.write(:serialized, [123])
    end
  end

end
