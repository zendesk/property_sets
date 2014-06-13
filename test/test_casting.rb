require File.expand_path('../helper', __FILE__)
require 'property_sets/casting'

describe PropertySets::Casting do
  describe "#read" do
    it "return nil when given value nil regardless of type" do
      assert_equal nil, PropertySets::Casting.read(:string, nil)
      assert_equal nil, PropertySets::Casting.read(:hello, nil)
    end

    it "leave serialized data alone" do
      assert_equal [1,2,3], PropertySets::Casting.read(:serialized, [1, 2, 3])
    end

    it "reads boolean" do
      assert_equal true, PropertySets::Casting.read(:boolean, "true")
      assert_equal true, PropertySets::Casting.read(:boolean, "1")
      assert_equal true, PropertySets::Casting.read(:boolean, "something")
      assert_equal true, PropertySets::Casting.read(:boolean, "on")
      assert_equal true, PropertySets::Casting.read(:boolean, true)
      assert_equal true, PropertySets::Casting.read(:boolean, 1111)
    end
  end

  describe "#write" do
    it "return nil when given value nil regardless of type" do
      assert_equal nil, PropertySets::Casting.write(:string, nil)
      assert_equal nil, PropertySets::Casting.write(:hello, nil)
    end

    it "convert time instances to UTC" do
      time = Time.now.in_time_zone("CET")
      assert PropertySets::Casting.write(:datetime, time) =~ /UTC$/
    end

    it "convert integers to strings" do
      assert_equal "123", PropertySets::Casting.write(:integer, 123)
    end

    it "convert random things to booleans" do
      assert_equal "1", PropertySets::Casting.write(:boolean, 1)
      assert_equal "1", PropertySets::Casting.write(:boolean, true)
      assert_equal "1", PropertySets::Casting.write(:boolean, "dfsdff")

      assert_equal "0", PropertySets::Casting.write(:boolean, "")
      assert_equal "0", PropertySets::Casting.write(:boolean, nil)
      assert_equal "0", PropertySets::Casting.write(:boolean, false)
      assert_equal "0", PropertySets::Casting.write(:boolean, 0)
      assert_equal "0", PropertySets::Casting.write(:boolean, "off")
      assert_equal "0", PropertySets::Casting.write(:boolean, "n")
    end

    it "leave serialized data alone for the record to deal with" do
      a = [123]
      assert_equal a, PropertySets::Casting.write(:serialized, a)
    end
  end
end
