require 'helper'

class Account < ActiveRecord::Base
  property_set :settings do
    property :foo
    property :bar
    property :baz
    property :hep, :default   => 'skep'
    property :bob
    property :bla, :protected => true
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

    should "support protecting attributes" do
      assert @account.settings.bla.protected?
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

    should "be creatable through association" do
      assert @account.settings.foo.create.id
      @account.settings.foo.destroy
      @account.reload
      assert @account.settings.foo.new_record?
      assert @account.settings.foo.create(:value => 8)
      assert @account.settings.foo.id
      assert @account.settings.foo.value == "8"
      assert @account.settings.hep.create
      assert_equal @account.settings.hep.value, "skep"
    end

    should "be destroyable through association" do
      assert !@account.settings.foo?
      assert @account.settings.foo = "1"
      assert @account.settings.foo?
      assert @account.settings.foo.destroy
      @account.settings.reload
      assert !@account.settings.foo?
    end

    should "support enable/disable semantics" do
      assert !@account.settings.foo?
      assert @account.settings.foo.id.nil?
      @account.settings.foo.enable
      assert @account.settings.foo.id.present?
      assert @account.settings.foo?
      @account.settings.foo.disable
      assert !@account.settings.foo?
    end

    should "coerce everything but nil to string" do
      assert @account.settings.foo.create(:value => 3)
      assert @account.settings.foo.value == "3"
      assert @account.settings.foo.create(:value => nil)
      assert @account.settings.foo.value.nil?
    end

    context "bulk updates" do
      should "support bulk create/update of multiple properties in one go" do
        [ @account, Account.new(:name => "Mibble") ].each do |account|
          account.settings.bulk(:foo => "123", :bar => "456")
          account.save!

          assert_equal account.reload.settings.size, 2
          assert_equal account.settings.foo.value, "123"
          assert_equal account.settings.foo.name, "foo"
          assert_equal account.settings.bar.value, "456"
          assert_equal account.settings.bar.name, "bar"

          account.settings.bulk(:bar => "789", :baz => "012")
          account.save!

          assert_equal account.reload.settings.size, 3
          assert_equal account.settings.foo.value, "123"
          assert_equal account.settings.bar.value, "789"
          assert_equal account.settings.baz.value, "012"
        end
      end

      should "be updateable as AR nested attributes" do
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

      should "be updateable as a nested structure" do
        assert !@account.settings.foo?
        assert !@account.settings.bar?
        assert !@account.settings.foo.id
        assert !@account.settings.bar.id
        assert @account.settings.empty?

        attribs = {
          :name => "Kim",
          :property_sets => {
            :settings => { :foo => "1", :bar => "0" }
          }
        }

        assert @account.update_attributes(attribs)
        @account.save!

        assert @account.settings.foo?
        assert !@account.settings.bar?
        assert @account.settings.foo.id
        assert @account.settings.bar.id
        assert @account.settings.foo.value == "1"
        assert @account.settings.bar.value == "0"

        attribs = {
          :name => "Kim",
          :property_sets => {
            :settings => { :foo => "1", :bar => "1", :baz => "1", :bla => "1" }
          }
        }

        assert @account.update_attributes!(attribs)

        assert @account.settings.foo?
        assert @account.settings.bar?
        assert @account.settings.baz?
        assert !@account.settings.bla?
      end
    end

    context "view construction" do
      should "provide a form builder proxy" do
        proxy = ActionView::FormBuilder.new.property_set(:foo)
        assert proxy.is_a?(PropertySets::FormBuilderProxy)
        assert_equal :foo, proxy.property_set
        proxy.builder.expects(:property_set_check_box).once.with(:foo, :bar, {}, "1", "0")
        proxy.check_box(:bar)
      end
    end
  end
end
