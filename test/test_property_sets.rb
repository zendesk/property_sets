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

    context "on a new account" do
      should "be empty" do
        assert @account.settings.empty?
        assert @account.texts.empty?
      end

      should "respond to defaults" do
        assert_equal false, @account.settings.bar?
        assert_equal nil, @account.settings.bar.value
        assert_equal true, @account.settings.hep?
        assert_equal 'skep', @account.settings.hep.value
      end
    end

    context "validations" do
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
    end

    context "access" do
      should "support creation" do
        assert !@account.settings.foo?
        assert @account.settings.foo = "1"
        assert @account.settings.size == 1
        assert @account.texts.size == 0
        assert @account.settings.foo?
        assert @account.settings.foo = "2"
        assert @account.settings.size == 1
        assert @account.settings.foo?
      end

      should "support destruction" do
        assert !@account.settings.foo?
        assert @account.settings.foo = "1"
        assert @account.settings.foo?
        assert @account.settings.foo.destroy
        @account.settings.reload
        assert !@account.settings.foo?
      end

      should "support building multiple properties in one go" do
        @account.settings.build(:foo => "123", :bar => "456")
        @account.save!
        assert_equal @account.reload.settings.size, 2
        assert_equal @account.settings.foo.value, "123"
        assert_equal @account.settings.foo.name, "foo"
        assert_equal @account.settings.bar.value, "456"
        assert_equal @account.settings.bar.name, "bar"
      end
    end
  end

#      should "moo" do
#        assert !a.settings.foo?
#        assert !a.settings.reports?
#
#        a.update_attributes(:settings => { :foo => '1', :reports => '1' })
#        assert a.settings.foo?
#        assert a.settings.reports?
#
#        a.update_attributes(:settings => { :foo => '0', :reports => '0' })
#        assert !a.settings.foo?
#        assert !a.settings.reports?
#      end
#
#      should "support protecting certain settings from mass updates" do
#        a = Account.create(:name => 'name')
#        assert a.settings.empty?
#        assert !a.settings.foo?
#        assert !a.settings.ssl?
#
#        a.update_attributes(:settings => {:foo => '1', :ssl => '1'})
#        assert a.settings.foo?
#        assert !a.settings.ssl?
#
#        assert a.settings.ssl.create
#        assert a.settings.ssl?
#        a.update_attributes(:settings => {:foo => '0', :ssl => '0'})
#        assert !a.settings.foo?
#        assert a.settings.ssl?
#      end

end
