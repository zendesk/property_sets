require 'spec_helper'

describe PropertySets::Delegator do
  let(:account) { Account.create(:name => "Name") }
  let(:default) { 'skep' }

  describe "read" do
    it "not add a property" do
      account.old
      expect(account.settings.size).to eq(0)
    end

    it "delegate read to default" do
      expect(account.old).to eq(default)
    end

    it "delegate read to property value" do
      account.settings.hep = 'new'
      expect(account.old).to eq('new')
    end
  end

  describe "write" do
    it "add a property" do
      account.old = 'new'
      expect(account.settings.size).to eq(1)
    end

    it "delegate write" do
      account.old = 'new'
      expect(account.settings.hep).to eq('new')
      expect(account.old).to eq('new')
    end
  end

  describe "changed?" do
    it "does not add a property" do
      account.old_changed?
      expect(account.settings.size).to eq(0)
    end

    it "is not changed when unchanged" do
      expect(account.old_changed?).to be false
    end

    it "is changed with new value" do
      account.old = "new"
      expect(account.old_changed?).to be true
    end

    it "is changed with new falsy value" do
      account.old = false
      expect(account.old_changed?).to be true
    end

    it "is changed with new nil value" do
      account.old = nil
      expect(account.old_changed?).to be true
    end

    it "is not changed with default value" do
      account.old = default
      expect(account.old_changed?).to be false
    end

    it "does not perform queries when association was never loaded and could not possibly be changed" do
      account
      assert_sql_queries 0 do
        expect(account.old_changed?).to be false
      end
    end
  end

  describe "before_type_case" do
    it "not add a property" do
      account.old_before_type_cast
      expect(account.settings.size).to eq(0)
    end

    it "return default" do
      expect(account.old_before_type_cast).to eq(default)
    end

    it "return setting" do
      account.old = "new"
      expect(account.old_before_type_cast).to eq("new")
    end
  end
end
