require "spec_helper"
require "property_sets/casting"

describe PropertySets::Casting do
  describe "#read" do
    it "return nil when given value nil regardless of type" do
      expect(PropertySets::Casting.read(:string, nil)).to be_nil
      expect(PropertySets::Casting.read(:hello, nil)).to be_nil
    end

    it "leave serialized data alone" do
      expect(PropertySets::Casting.read(:serialized, [1, 2, 3])).to eq([1, 2, 3])
    end

    it "reads boolean" do
      expect(PropertySets::Casting.read(:boolean, "true")).to be true
      expect(PropertySets::Casting.read(:boolean, "1")).to be true
      expect(PropertySets::Casting.read(:boolean, "something")).to be true
      expect(PropertySets::Casting.read(:boolean, "on")).to be true
      expect(PropertySets::Casting.read(:boolean, true)).to be true
      expect(PropertySets::Casting.read(:boolean, 1111)).to be true
    end
  end

  describe "#write" do
    it "return nil when given value nil regardless of type" do
      expect(PropertySets::Casting.write(:string, nil)).to be_nil
      expect(PropertySets::Casting.write(:hello, nil)).to be_nil
    end

    it "convert time instances to UTC" do
      time = Time.new(2000, 1, 1, 12, 0, 0, "+01:00")
      expect(PropertySets::Casting.write(:datetime, time)).to eq("2000-01-01 11:00:00 UTC")
    end

    it "convert integers to strings" do
      expect(PropertySets::Casting.write(:integer, 123)).to eq("123")
    end

    it "convert random things to booleans" do
      expect(PropertySets::Casting.write(:boolean, 1)).to eq("1")
      expect(PropertySets::Casting.write(:boolean, true)).to eq("1")
      expect(PropertySets::Casting.write(:boolean, "dfsdff")).to eq("1")

      expect(PropertySets::Casting.write(:boolean, "")).to eq("0")
      expect(PropertySets::Casting.write(:boolean, nil)).to be_nil
      expect(PropertySets::Casting.write(:boolean, false)).to eq("0")
      expect(PropertySets::Casting.write(:boolean, 0)).to eq("0")
      expect(PropertySets::Casting.write(:boolean, "off")).to eq("0")
      expect(PropertySets::Casting.write(:boolean, "n")).to eq("0")
    end

    it "leave serialized data alone for the record to deal with" do
      a = [123]
      expect(PropertySets::Casting.write(:serialized, a)).to eq(a)
    end
  end
end
