require File.expand_path(File.dirname(__FILE__) + '/helper')

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

    should "register the property sets used on a class" do
      assert_equal [ :settings, :texts ], Account.property_set_index
    end

    should "support protecting attributes" do
      assert @account.settings.protected?(:pro)
      assert !@account.settings.protected?(:foo)
    end

    should "allow enabling/disabling a property" do
      assert @account.settings.hep?
      @account.settings.disable(:hep)
      assert !@account.settings.hep?
      @account.settings.enable(:hep)
      assert @account.settings.hep?
    end

    should "be empty on a new account" do
      assert @account.settings.empty?
      assert @account.texts.empty?

      assert !@account.texts.foo?
      assert !@account.texts.bar?
      assert @account.texts.foo.nil?
      assert @account.texts.bar.nil?
    end

    should "respond with defaults" do
      assert_equal false, @account.settings.bar?
      assert_equal nil, @account.settings.bar
      assert_equal true, @account.settings.hep?
      assert_equal 'skep', @account.settings.hep
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
      @account.settings.create!(:name => "unique")
      assert_raise ActiveRecord::RecordInvalid do
        @account.settings.create!(:name => "unique")
      end
    end

    should "be creatable using the = operator" do
      assert !@account.settings.foo?
      [ "1", "2" ].each do |value|
        assert @account.settings.foo = value
        assert @account.settings.foo?
        assert @account.settings.size == 1
      end

      assert @account.texts.empty?
    end

    should "coerce everything but nil to string" do
      @account.settings.foo = 3
      assert @account.settings.foo == "3"
      @account.settings.foo = nil
      assert @account.settings.foo.nil?
    end

    context "#set" do
      should "support writing multiple values to the association" do
        assert !@account.settings.foo?
        assert !@account.settings.bar?

        @account.settings.set(:foo => "123", :bar => "456")

        assert @account.settings.foo?
        assert @account.settings.bar?
      end

      should "work identically for new and existing owner objects" do
        [ @account, Account.new(:name => "Mibble") ].each do |account|
          account.settings.set(:foo => "123", :bar => "456")

          assert_equal account.settings.size, 2
          assert_equal account.settings.foo, "123"
          assert_equal account.settings.bar, "456"

          account.settings.set(:bar => "789", :baz => "012")

          assert_equal account.settings.size, 3
          assert_equal account.settings.foo, "123"
          assert_equal account.settings.bar, "789"
          assert_equal account.settings.baz, "012"
        end
      end

      should "be updateable as AR nested attributes" do
        assert @account.texts_attributes = [{ :name => "foo", :value => "1"  }, { :name => "bar", :value => "0"  }]
        @account.save!

        assert @account.texts.foo == "1"
        assert @account.texts.bar == "0"

        @account.update_attributes!(:texts_attributes => [
          { :id => @account.texts.lookup(:foo).id, :name => "foo", :value => "0"  },
          { :id => @account.texts.lookup(:bar).id, :name => "bar", :value => "1" }
        ])

        assert @account.texts.foo == "0"
        assert @account.texts.bar == "1"
      end

      should "be updateable as a nested structure" do
        attribs = {
          :name => "Kim", :settings => { :foo => "1", :bar => "0" }
        }

        assert @account.update_attributes(attribs)
        @account.save!

        assert @account.settings.foo?
        assert !@account.settings.bar?
        assert @account.settings.foo == "1"
        assert @account.settings.bar == "0"
        assert !@account.settings.pro?

        attribs = {
          :name => "Kim", :settings => { :foo => "1", :bar => "1", :baz => "1", :pro => "1" }
        }

        assert @account.update_attributes!(attribs)

        assert @account.settings.foo?
        assert @account.settings.bar?
        assert @account.settings.baz?
        assert !@account.settings.pro?
      end
    end
  end
end
