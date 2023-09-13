require 'spec_helper'

old, $-w = $-w, nil
# sqlite type differences:
PropertySets::PropertySetModel::COLUMN_TYPE_LIMITS =
  PropertySets::PropertySetModel::COLUMN_TYPE_LIMITS.merge('varchar' => 65535)
$-w = old

describe PropertySets do
  let(:account) { Parent::Account.create(:name => "Name") }
  let(:relation) { Parent::Account.reflections["settings"] }

  it "construct the container class" do
    expect(defined?(Parent::AccountSetting)).to be_truthy
    expect(defined?(Parent::AccountText)).to be_truthy
    expect(defined?(Parent::AccountTypedDatum)).to be_truthy
  end

  it "register the property sets used on a class" do
    %i(settings texts validations typed_data).each do |name|
      expect(Parent::Account.property_set_index).to include(name)
    end
  end

  it "sets inverse_of" do
    expect(relation.inverse_of.klass).to eq Parent::Account
  end

  it "reopening property_set is idempotent, first one wins on options etc" do
    expect(Array(relation.options[:extend])).to include Parent::Account::Woot
    expect(account.settings.extensions).to include Parent::Account::Woot
  end

  it "allow the owner class to be customized" do
    (Flux = Class.new(ActiveRecord::Base)).property_set(:blot, {
      :owner_class_name => 'Foobar'
    }) { property :test }

    expect(defined?(FoobarBlot)).to be_truthy
  end

  it "pass-through any options from the second parameter" do
    class AnotherThing < ActiveRecord::Base
      self.table_name = "things" # cheat and reuse things table
    end

    AnotherThing.property_set(:settings, :extend => Parent::Account::Woot,
                              :table_name => "thing_settings")

    expect(AnotherThing.new.settings.extensions).to include(::Parent::Account::Woot)
  end

  it "support protecting attributes" do
    expect(account.settings.protected?(:pro)).to be true
    expect(account.settings.protected?(:foo)).to be false
  end

  it "allow enabling/disabling a property" do
    expect(account.settings.hep?).to be true
    account.settings.disable(:hep)
    expect(account.settings.hep?).to be false
    account.settings.enable(:hep)
    expect(account.settings.hep?).to be true

    account = Parent::Account.new
    expect(account.settings.foo?).to be false
    account.settings.enable(:foo)
    expect(account.settings.foo?).to be true
  end

  it "be empty on a new account" do
    expect(account.settings).to be_empty
    expect(account.texts)   .to be_empty

    expect(account.texts.foo?).to be false
    expect(account.texts.bar?).to be false

    expect(account.texts.foo).to be_nil
    expect(account.texts.bar).to be_nil
  end

  it "respond with defaults" do
    expect(account.settings.bar?)      .to be false
    expect(account.settings.bar)       .to be_nil
    expect(account.settings.hep?)      .to be true
    expect(account.settings.hep)       .to eq('skep')
    expect(account.settings.bool_nil)  .to be_nil
    expect(account.settings.bool_nil2) .to be_nil
    expect(account.settings.bool_false).to be false
    expect(account.settings.bool_true) .to be true
  end

  it "be flexible when fetching property data" do
    expect(account.settings.association_class.default(:hep)) .to eq('skep')
    expect(account.settings.association_class.default('hep')).to eq('skep')
  end

  describe 'querying for a setting that does not exist' do
    before do
      expect(account.settings).to eq([])
      expect(account.settings.hep?).to be true
    end

    it 'not add a new setting' do
      expect(account.settings).to eq([])
    end

    it 'give back the default value' do
      expect(account.settings.hep).to eq('skep')
    end
  end

  it "reject settings with an invalid name" do
    s = Parent::AccountSetting.new(:account => account)

    valids   = %w(hello hel_lo hell0) + [:hello]
    invalids = %w(_hello)

    valids.each do |valid|
      s.name = valid
      expect(s).to be_valid, "#{valid} is invalid: #{s.errors.inspect}"
    end

    invalids.each do |invalid|
      s.name = invalid
      expect(s).to_not be_valid, "#{invalid} is valid"
    end
  end

  it "validate uniqueness of settings" do
    account.settings.create!(:name => "unique")
    expect {
      account.settings.create!(:name => "unique")
    }.to raise_error(ActiveRecord::RecordInvalid, /Name has already been taken/)
  end

  it "be creatable using the = operator" do
    expect(account.settings.foo?).to be false
    [ "1", "2" ].each do |value|
      expect(account.settings.foo = value).to be_truthy
      expect(account.settings.foo?)       .to be true
      expect(account.settings.size).to eq(1)
    end

    expect(account.texts).to be_empty
  end

  it "coerce everything but nil to string" do
    account.settings.foo = 3
    account.save
    expect(account.settings.foo).to eq("3")
    account.settings.foo = nil
    account.save
    expect(account.settings.foo).to be_nil
  end

  it "reference the owner instance when constructing a new record" do
    record = account.settings.lookup(:baz)
    expect(record).to be_new_record
    expect(record.account.id).to eq(account.id)
  end

  it "reference the owner instance when constructing a new record ...on a new record" do
    account = Parent::Account.new(:name => "New")
    record  = account.settings.lookup(:baz)

    expect(record).to be_new_record
    expect(record.account).to eq(account)
  end

  describe "validations" do
    it "add an error when violated" do
      account.validations.validated = "hello"
      expect(account).to_not be_valid
      expect(account.errors.full_messages.first).to match(/BEEP$/)
    end
  end

  describe "#get" do
    before { account.settings.set(:baz => "456") }

    it "fetch property pairs with string arguments" do
      expect(account.settings.lookup_without_default(:baz)).to be_truthy
      expect(account.settings.get(["baz"])).to eq("baz" => "456")
    end

    it "fetch property pairs with symbol arguments" do
      expect(account.settings.get([:baz])).to eq("baz" => "456")
    end

    it "return all property pairs if no arguments are provided" do
      expect(account.settings.get.keys.sort).to eq(
        %w(bar baz bool_false bool_nil bool_nil2 bool_true foo hep pro).sort
      )
    end

    it "ignore non-existent keys" do
      expect(account.settings.get([:baz, :red])).to eq("baz" => "456")
    end

    it "include default property pairs" do
      expect(account.settings.lookup_without_default(:hep)).to be_nil
      expect(account.settings.get(["hep"])).to eq("hep" => "skep")
    end

    it "return a hash with values that can be fetched by string or symbol" do
      expect(account.settings.get(["baz"]).fetch(:baz)).to eq("456")
    end

    it "return serialized values" do
      account.typed_data.set(:serialized_prop => [1, 2])
      expect(account.typed_data.lookup_without_default(:serialized_prop)).to be_truthy
      expect(account.typed_data.get([:serialized_prop])).to eq("serialized_prop" => [1, 2])
    end
  end

  describe "#set" do
    it "support writing multiple values to the association" do
      expect(account.settings.foo?).to be_falsy
      expect(account.settings.bar?).to be_falsy

      account.settings.set(:foo => "123", :bar => "456")

      expect(account.settings.foo?).to be_truthy
      expect(account.settings.bar?).to be_truthy
    end

    it "convert string keys to symbols to ensure consistent lookup" do
      account.settings.set(:foo => "123")
      account.settings.set("foo" => "456")
      expect(account.save!).to be true
    end

    it "work identically for new and existing owner objects" do
      [ account, Parent::Account.new(:name => "Mibble") ].each do |account|
        account.settings.set(:foo => "123", :bar => "456")

        expect(account.settings.size).to eq(2)
        expect(account.settings.foo) .to eq("123")
        expect(account.settings.bar) .to eq("456")

        account.settings.set(:bar => "789", :baz => "012")

        expect(account.settings.size).to eq(3)
        expect(account.settings.foo) .to eq("123")
        expect(account.settings.bar) .to eq("789")
        expect(account.settings.baz) .to eq("012")
      end
    end

    it "be updateable as AR nested attributes" do
      expect(
        account.texts_attributes = [{ :name => "foo", :value => "1"  }, { :name => "bar", :value => "0"  }]
      ).to be_truthy

      account.save!

      expect(account.texts.foo).to eq("1")
      expect(account.texts.bar).to eq("0")

      account.update_attributes!(:texts_attributes => [
        { :id => account.texts.lookup(:foo).id, :name => "foo", :value => "0"  },
        { :id => account.texts.lookup(:bar).id, :name => "bar", :value => "1" }
      ])

      expect(account.texts.foo).to eq("0")
      expect(account.texts.bar).to eq("1")
    end

    it "be updateable as a nested structure" do
      account.settings.baz = "1"
      account.save!

      expect(account.settings.foo?).to be false
      expect(account.settings.bar?).to be false
      expect(account.settings.baz?).to be true
      expect(account.settings.pro?).to be false

      account.update_attributes!(
        :name => "Kim",
        :settings => { :foo => "1", :baz => "0", :pro => "1" }
      )

      account.reload

      # set
      expect(account.settings.foo?).to be true
      expect(account.settings.foo).to eq("1")

      # kept
      expect(account.settings.bar?).to be false
      expect(account.settings.bar).to be_nil

      # unset
      expect(account.settings.baz?).to be false
      expect(account.settings.baz).to eq("0")

      # protected -> not set
      expect(account.settings.pro?).to be false
      expect(account.settings.pro).to be_nil
    end
  end

  describe "lookup" do
    describe "with data" do
      it "return the data" do
        account.texts.foo = "1"
        expect(account.texts.lookup(:foo).value).to eq("1")
      end

      it "returns false" do
        account.settings.bool_nil = false
        expect(account.settings.lookup(:bool_nil).value).to eq("0")
      end
    end

    describe "without data" do
      it "returns nil without default" do
        expect(account.texts.lookup(:foo).value).to be_nil
      end

      it "create a new record" do
        expect(account.texts.detect { |p| p.name == "foo" }).to be_falsy
        account.texts.lookup(:foo).value
        expect(account.texts.detect { |p| p.name == "foo" }).to be_truthy
      end

      it "returns nil with default" do
        expect(account.texts.lookup(:hep).value).to be_nil
      end

      it "returns nil with default for booleans" do
        expect(account.texts.lookup(:bool_false).value).to be_nil
      end
    end
  end

  describe "lookup_without_default" do
    it "return the row if it exists" do
      account.texts.foo = "1"
      expect(account.texts.lookup_without_default(:foo).value).to eq("1")
    end

    it "return nil otherwise" do
      expect(account.texts.lookup_without_default(:foo)).to be_nil
    end
  end

  describe "save" do
    it "call save on all dem records" do
      account.settings.foo = "1"
      account.settings.bar = "2"
      account.settings.save

      account.reload
      expect(account.settings.foo).to eq("1")
      expect(account.settings.bar).to eq("2")
    end

    it "sets forwarded attributes" do
      other_account = Other::Account.new(name: "creating", old: "forwarded value")
      other_account.save
      expect(other_account.old).to eq("forwarded value")
    end
  end

  describe "update_attribute for forwarded method" do
    it "creates changed attributes" do
      account.update_attribute(:old, "it works!")
      expect(account.previous_changes["old"].last).to eq("it works!")
      expect(Parent::Account.find(account.id).old).to eq("it works!")
    end

    it "updates changed attributes for existing property_set data" do
      account.settings.hep = "saved previously"
      account.save
      account.update_attribute(:old, "it works!")
      expect(account.previous_changes["old"].last).to eq("it works!")
      expect(Parent::Account.find(account.id).old).to eq("it works!")
    end

    it "updates changed attributes for existing property_set data after set through forwarded method" do
      account.old = "saved previously"
      account.save
      account.update_attribute(:old, "it works!")
      expect(account.previous_changes["old"].last).to eq("it works!")
      expect(Parent::Account.find(account.id).old).to eq("it works!")
    end
  end

  describe "assign_attributes for forwarded method" do
    it "sets the attribute value" do
      account.assign_attributes(old: "assigned!")
      expect(account.old).to eq("assigned!")
    end

    it "sets the object's changed attributes" do
      account.assign_attributes(old: "assigned!")
      expect(account).to be_changed
      expect(account.changed_attributes).to include(:old)
    end
  end

  describe "update_columns for forwarded method" do
    it "does not write to a missing column" do
      account.update_columns(name: 'test', old: "it works!")
      expect(account.previous_changes).to_not include("old")
    end

    it "does not prevent other non-delegated property set models from updating" do
      thing = Thing.create(name: 'test')
      expect(thing.update_columns(name: 'it works')).to be
    end
  end

  describe "typed columns" do

    it "typecast the default value" do
      expect(account.typed_data.association_class.default(:default_prop)).to eq(123)
    end

    describe "string data" do
      it "be writable and readable" do
        account.typed_data.string_prop = "foo"
        expect(account.typed_data.string_prop).to eq("foo")
      end
    end

    describe "floating point data" do
      it "be writable and readable" do
        account.typed_data.float_prop = 1.97898
        expect(account.typed_data.float_prop).to eq(1.97898)
        account.save!
        expect(account.typed_data.float_prop).to eq(1.97898)
      end
    end

    describe "integer data" do
      it "be writable and readable" do
        account.typed_data.int_prop = 25
        expect(account.typed_data.int_prop).to eq(25)
        account.save!
        expect(account.typed_data.int_prop).to eq(25)

        expect(account.typed_data.lookup("int_prop").value).to eq("25")
      end
    end

    describe "datetime data" do
      it "be writable and readable" do
        ts = Time.at(Time.now.to_i)
        account.typed_data.datetime_prop = ts

        expect(account.typed_data.datetime_prop).to eq(ts)
        account.save!
        expect(account.typed_data.datetime_prop).to eq(ts)
      end

      it "store data in UTC" do
        ts = Time.at(Time.now.to_i)
        string_rep = ts.in_time_zone("UTC").to_s
        account.typed_data.datetime_prop = ts
        account.save!
        expect(account.typed_data.lookup("datetime_prop").value).to eq(string_rep)
      end
    end

    describe "serialized data" do
      it "store data in json" do
        value = {:a => 1, :b => 2}
        account.typed_data.serialized_prop = value
        account.save!
        account.reload
        expect(account.typed_data.serialized_prop).to eq('a' => 1, 'b' => 2)
      end

      it "retrieve default values from JSON" do
        expect(account.typed_data.serialized_prop_with_default).to eq([])
      end

      it "not overflow the column" do
        account.typed_data.serialized_prop = (1..100_000).to_a
        expect(account.typed_data.lookup(:serialized_prop)).to_not be_valid
        expect(account.save).to be false
      end

      it "not overflow on other text types" do
        account.tiny_texts.serialized = (1..2**10).to_a # column size is 2^8 - 1
        expect(account.tiny_texts.lookup(:serialized)).to_not be_valid
        expect(account.save).to be false
      end

      it "allow for destructive operators" do
        value = {:a => 1, :b => 2}
        account.typed_data.serialized_prop = value
        account.typed_data.serialized_prop[:c] = 3
        expect(account.typed_data.serialized_prop[:c]).to eq(3)
      end

      it "deal with nil values properly going in" do
        account.typed_data.serialized_prop = nil
        expect {
          account.save!
        }.to_not raise_error
      end

      it "deal with nil values properly coming out" do
        expect(account.typed_data.serialized_prop).to be_nil
      end
    end
  end
end
