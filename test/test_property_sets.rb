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
      [ :settings, :texts, :validations, :typed_data ].each do |name|
        assert Account.property_set_index.include?(name)
      end
    end

    should "pass-through any options from the second parameter" do
      Account.expects(:has_many).with { |association, h|
        association == :foo && h[:conditions] == "bar"
      }
      Account.property_set(:foo, :conditions => "bar") {}
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

      account = Account.new
      assert !account.settings.foo?
      account.settings.enable(:foo)
      assert account.settings.foo?
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

    should "be flexible when fetching property data" do
      assert_equal 'skep', @account.settings.default(:hep)
      assert_equal 'skep', @account.settings.default('hep')
    end

    context 'querying for a setting that does not exist' do
      setup do
        assert_equal([], @account.settings)
        assert_equal(true, @account.settings.hep?)
      end

      should 'not add a new setting' do
        assert_equal([], @account.settings)
      end

      should 'give back the default value' do
        assert_equal('skep', @account.settings.hep)
      end
    end

    should "reject settings with an invalid name" do
      s = AccountSetting.new(:account => @account)

      [ 'hello', 'hel_lo', 'hell0' ].each do |valid|
        s.name = valid
        assert s.valid?, "#{valid} is invalid: #{s.errors.inspect}"
      end

      [ '_hello', :hello ].each do |invalid|
        s.name = invalid
        assert !s.valid?, "#{invalid} is valid"
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
      @account.save
      assert @account.settings.foo == "3"
      @account.settings.foo = nil
      @account.save
      assert @account.settings.foo.nil?
    end

    should "reference the owner instance when constructing a new record" do
      record = @account.settings.lookup(:baz)
      assert record.new_record?
      assert record.account.id == @account.id
    end

    should "reference the owner instance when constructing a new record ...on a new record" do
      account = Account.new(:name => "New")
      record  = account.settings.lookup(:baz)

      assert record.new_record?
      assert record.account == account
    end

    context "validations" do
      should "add an error when violated" do
        @account.validations.validated = "hello"
        assert !@account.valid?
        assert_match /BEEP$/, @account.errors.full_messages.first
      end
    end

    context "#get" do
      setup { @account.settings.set(:baz => "456") }

      should "fetch property pairs with string arguments" do
        assert @account.settings.lookup_without_default(:baz)
        assert_equal({"baz" => "456"}, @account.settings.get(["baz"]))
      end

      should "fetch property pairs with symbol arguments" do
        assert_equal({"baz" => "456"}, @account.settings.get([:baz]))
      end

      should "return all property pairs if no arguments are provided" do
        assert_same_elements(
          ["foo", "bar", "baz", "hep", "pro"],
          @account.settings.get.keys
        )
      end

      should "ignore non-existent keys" do
        assert_equal({"baz" => "456"}, @account.settings.get([:baz, :red]))
      end

      should "include default property pairs" do
        assert_nil @account.settings.lookup_without_default(:hep)
        assert_equal({"hep" => "skep"}, @account.settings.get(["hep"]))
      end

      should "return a hash with values that can be fetched by string or symbol" do
        assert_equal "456", @account.settings.get(["baz"]).fetch(:baz)
      end

      should "return serialized values" do
        @account.typed_data.set(:serialized_prop => [1, 2])
        assert @account.typed_data.lookup_without_default(:serialized_prop)
        assert_equal({"serialized_prop" => [1, 2]}, @account.typed_data.get([:serialized_prop]))
      end
    end

    context "#set" do
      should "support writing multiple values to the association" do
        assert !@account.settings.foo?
        assert !@account.settings.bar?

        @account.settings.set(:foo => "123", :bar => "456")

        assert @account.settings.foo?
        assert @account.settings.bar?
      end

      should "convert string keys to symbols to ensure consistent lookup" do
        @account.settings.set(:foo => "123")
        @account.settings.set("foo" => "456")
        assert @account.save!
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
        @account.settings.baz = "1"
        @account.save!

        assert !@account.settings.foo?
        assert !@account.settings.bar?
        assert @account.settings.baz?
        assert !@account.settings.pro?

        @account.update_attributes!(
          :name => "Kim",
          :settings => { :foo => "1", :baz => "0", :pro => "1" }
        )

        @account.reload

        # set
        assert @account.settings.foo?
        assert_equal "1", @account.settings.foo

        # kept
        assert !@account.settings.bar?
        assert_equal nil, @account.settings.bar

        # unset
        assert !@account.settings.baz?
        assert_equal "0", @account.settings.baz

        # protected -> not set
        assert !@account.settings.pro?
        assert_equal nil, @account.settings.pro
      end
    end

    context "lookup" do
      context "with data" do
        setup { @account.texts.foo = "1" }

        should "return the data" do
          assert_equal "1", @account.texts.lookup(:foo).value
        end
      end

      context "without data" do
        should "create a new record, returning the default" do
          assert_equal nil, @account.texts.lookup(:foo).value
          assert @account.texts.detect { |p| p.name == "foo" }
        end
      end
    end

    context "lookup_without_default" do
      should "return the row if it exists" do
        @account.texts.foo = "1"
        assert_equal "1", @account.texts.lookup_without_default(:foo).value
      end

      should "return nil otherwise" do
        assert_equal nil,  @account.texts.lookup_without_default(:foo)
      end
    end

    context "save" do
      should "call save on all dem records" do
        @account.settings.foo = "1"
        @account.settings.bar = "2"
        @account.settings.save

        @account.reload
        assert_equal "1", @account.settings.foo
        assert_equal "2", @account.settings.bar
      end
    end

    context "typed columns" do

      should "typecast the default value" do
        assert_equal 123, @account.typed_data.default(:default_prop)
      end

      context "string data" do
        should "be writable and readable" do
          @account.typed_data.string_prop = "foo"
          assert_equal "foo", @account.typed_data.string_prop
        end
      end

      context "floating point data" do
        should "be writable and readable" do
          @account.typed_data.float_prop = 1.97898
          assert_equal 1.97898,  @account.typed_data.float_prop
          @account.save!
          assert_equal 1.97898,  @account.typed_data.float_prop
        end
      end

      context "integer data" do
        should "be writable and readable" do
          @account.typed_data.int_prop = 25
          assert_equal 25,  @account.typed_data.int_prop
          @account.save!
          assert_equal 25,  @account.typed_data.int_prop

          assert_equal "25", @account.typed_data.lookup("int_prop").value
        end
      end

      context "datetime data" do
        should "be writable and readable" do
          ts = Time.at(Time.now.to_i)
          @account.typed_data.datetime_prop = ts

          assert_equal ts,  @account.typed_data.datetime_prop
          @account.save!
          assert_equal ts,  @account.typed_data.datetime_prop
        end

        should "store data in UTC" do
          ts = Time.at(Time.now.to_i)
          string_rep = ts.in_time_zone("UTC").to_s
          @account.typed_data.datetime_prop = ts
          @account.save!
          assert_equal string_rep, @account.typed_data.lookup("datetime_prop").value
        end
      end

      context "serialized data" do
        should "store data in json" do
          value = {:a => 1, :b => 2}
          @account.typed_data.serialized_prop = value
          @account.save!
          @account.reload
          assert_equal({'a' => 1, 'b' => 2},  @account.typed_data.serialized_prop)
        end

        should "retrieve default values from JSON" do
          assert_equal([],  @account.typed_data.serialized_prop_with_default)
        end

        should "not overflow the column" do
          @account.typed_data.serialized_prop = (1..100_000).to_a
          assert !@account.typed_data.lookup(:serialized_prop).valid?
          assert !@account.save
        end

        should "allow for destructive operators" do
          value = {:a => 1, :b => 2}
          @account.typed_data.serialized_prop = value
          @account.typed_data.serialized_prop[:c] = 3
          assert_equal 3, @account.typed_data.serialized_prop[:c]
        end

        should "deal with nil values properly going in" do
          @account.typed_data.serialized_prop = nil
          @account.save!
        end

        should "deal with nil values properly coming out" do
          assert_equal nil, @account.typed_data.serialized_prop
        end
      end
    end
  end
end
