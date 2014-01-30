require File.expand_path(File.dirname(__FILE__) + '/helper')

class TestDelegator < ActiveSupport::TestCase
  context PropertySets::Delegator do
    fixtures :accounts, :account_settings, :account_texts

    setup do
      @account = Account.create(:name => "Name")
      @default = 'skep'
    end

    context "read" do
      should "not add a property" do
        @account.old
        assert_equal 0, @account.settings.size
      end

      should "delegate read to default" do
        assert_equal @default, @account.old
      end

      should "delegate read to property value" do
        @account.settings.hep = 'new'
        assert_equal 'new', @account.old
      end
    end

    context "write" do
      should "add a property" do
        @account.old = 'new'
        assert_equal 1, @account.settings.size
      end

      should "delegate write" do
        @account.old = 'new'
        assert_equal 'new', @account.settings.hep
        assert_equal 'new', @account.old
      end
    end

    context "changed?" do
      should "not add a property" do
        @account.old_changed?
        assert_equal 0, @account.settings.size
      end

      should "not be changed" do
        assert_equal false, @account.old_changed?
      end

      should "be changed with new value" do
        @account.old = "new"
        assert_equal true, @account.old_changed?
      end

      should "not be changed with default value" do
        @account.old = @default
        assert_equal false, @account.old_changed?
      end
    end

    context "before_type_case" do
      should "not add a property" do
        @account.old_before_type_cast
        assert_equal 0, @account.settings.size
      end

      should "return default" do
        assert_equal @default, @account.old_before_type_cast
      end

      should "return setting" do
        @account.old = "new"
        assert_equal "new", @account.old_before_type_cast
      end
    end
  end
end
