require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestMigrator < ActiveSupport::TestCase
  fixtures :accounts, :account_settings, :account_texts

  context PropertySets::Migrator do
    context "A property that is moving out of the accounts table and into property sets"  do
      setup do
        @account = Account.create(:name => "Name")

        @old_value = @account.read_attribute(:is_ssl_enabled)
        assert_equal false, @old_value
      end

      context "when the property hasn't yet migrated to the property set" do
        should "give back the old value" do
          assert_equal @old_value,  @account.is_ssl_enabled
        end

        should "log the method name when the attr_reader falls back" do
          @account.expects(:log_migrated_attribute_read).with(:is_ssl_enabled)
          @account.is_ssl_enabled
        end

        should "log the method name when the predicate method falls back" do
          @account.expects(:log_migrated_attribute_read).with(:is_ssl_enabled?)
          @account.is_ssl_enabled?
        end

        should "log the method name when the before_type_cast method falls back" do
          @account.expects(:log_migrated_attribute_read).with(:is_ssl_enabled_before_type_cast)
          @account.is_ssl_enabled_before_type_cast
        end

        context "_changed?" do
          should "be true when changed" do
            @account.is_ssl_enabled = true
            assert @account.is_ssl_enabled_changed?
          end

          should "log the method name whe the _changed? method reads the attribute" do
            @account.expects(:log_migrated_attribute_read).with(:is_ssl_enabled_changed?)
            @account.is_ssl_enabled = true
            @account.is_ssl_enabled_changed?
          end

          should "be false when not changed" do
            assert !@account.is_ssl_enabled_changed?
          end

          should "be false when changed to the same value (as will be the case when backfilling)" do
            @account.is_ssl_enabled = @old_value
            assert !@account.is_ssl_enabled_changed?
          end
        end
      end

      context "when the property has migrated" do
        setup do
          @account.is_ssl_enabled = true
          @account.save!
        end

        should "not write to the old table" do
          assert_equal @old_value, @account.read_attribute(:is_ssl_enabled)
        end

        should "give back the new value" do
          assert_equal true,  @account.is_ssl_enabled
        end

        should "support update_attributes" do
          @account.update_attributes!(:is_ssl_enabled => false)
          assert_equal false,      @account.is_ssl_enabled
          assert_equal @old_value, @account.read_attribute(:is_ssl_enabled)
        end

        should "not log the method name" do
          @account.expects(:log_migrated_attribute_read).never
          @account.is_ssl_enabled?
        end
      end

      context "backfilling attributes from an account" do
        setup do
          @old_attributes = [ :is_ssl_enabled ]
          @new_attributes = [ :ssl_enabled ]
          @old_values = @account.attributes.slice(*@old_attributes)

          @account.save_migrated_properties_to_sets!
        end

        should "create all the attributes in settings and texts" do
          rows = @account.settings.map(&:name)
          assert (@new_attributes.map(&:to_s) - rows).empty?
        end

        should "have the same values" do
          @old_values.each do |k, v|
            assert_equal v, @account.send(k)
          end
        end
      end
    end
  end
end
