require 'helper'

class Account < ActiveRecord::Base
  property_set :settings do
    property :foo
    property :bar
    property :baz
    property :hep, :default   => 'skep'
    property :bob, :protected => true
  end

  property_set :texts do
    property :foo
    property :bar
  end

  accepts_nested_attributes_for :texts
end

class TestPropertySets < ActiveSupport::TestCase

  context "property sets" do
    fixtures :accounts, :account_settings, :account_texts

    setup do
      @account = Account.create(:name => "Name")
    end

    should "construct the container class" do
      assert defined?(AccountSetting)
      assert defined?(AccountText)
    end

    should "be empty on a new account" do
      assert @account.settings.empty?
      assert @account.texts.empty?
    end

    should "respond to defaults" do
      assert_equal false, @account.settings.bar?
      assert_equal nil, @account.settings.bar.value
      assert_equal true, @account.settings.hep?
      assert_equal 'skep', @account.settings.hep.value
      assert @account.settings.hep.id.nil?
    end

    should "reject settings with an invalid name" do
      s = AccountSetting.new(:account => @account)

      [ 'hello', 'hel_lo', 'hell0' ].each do |valid|
        s.name = valid
        assert s.valid?
      end

      [ '_hello', :hello ].each do |invalid|
        s.name = invalid
        assert !s.valid?
      end
    end

    should "validate uniqueness of settings" do
      AccountSetting.create!(:account => @account, :name => 'unique')
      assert_raise ActiveRecord::RecordInvalid do
        AccountSetting.create!(:account => @account, :name => 'unique')
      end
    end

    should "be creatable using the = operator" do
      assert !@account.settings.foo?
      assert @account.settings.foo = "1"
      assert @account.settings.size == 1
      assert @account.texts.size == 0
      assert @account.settings.foo?
      assert @account.settings.foo = "2"
      assert @account.settings.size == 1
      assert @account.settings.foo?
    end

    should "be destroyable through association" do
      assert !@account.settings.foo?
      assert @account.settings.foo = "1"
      assert @account.settings.foo?
      assert @account.settings.foo.destroy
      @account.settings.reload
      assert !@account.settings.foo?
    end

    should "support bulk build multiple properties in one go" do
      @account.settings.bulk(:foo => "123", :bar => "456")
      @account.save!
      assert_equal @account.reload.settings.size, 2
      assert_equal @account.settings.foo.value, "123"
      assert_equal @account.settings.foo.name, "foo"
      assert_equal @account.settings.bar.value, "456"
      assert_equal @account.settings.bar.name, "bar"
    end

    should "be updatable as nested attributes" do
      assert !@account.texts.foo?
      assert !@account.texts.bar?
      assert !@account.texts.foo.id
      assert !@account.texts.bar.id
      assert @account.texts.empty?

      assert @account.texts_attributes = [{ :name => "foo", :value => "1"  }, { :name => "bar", :value => "0"  }]
      @account.save!

      assert @account.texts.foo?
      assert !@account.texts.bar?
      assert @account.texts.foo.id
      assert @account.texts.bar.id

      @account.update_attributes!(:texts_attributes => [
        { :id => @account.texts.foo.id, :name => "foo", :value => "0"  },
        { :id => @account.texts.bar.id, :name => "bar", :value => "1" }
      ])
      assert !@account.texts.foo?
      assert @account.texts.bar?
    end
  end
end



