require File.expand_path('../helper', __FILE__)

describe PropertySets::Delegator do
  fixtures :accounts, :account_settings, :account_texts

  before do
    @account = Account.create(:name => "Name")
    @default = 'skep'
  end

  describe "read" do
    it "not add a property" do
      @account.old
      assert_equal 0, @account.settings.size
    end

    it "delegate read to default" do
      assert_equal @default, @account.old
    end

    it "delegate read to property value" do
      @account.settings.hep = 'new'
      assert_equal 'new', @account.old
    end
  end

  describe "write" do
    it "add a property" do
      @account.old = 'new'
      assert_equal 1, @account.settings.size
    end

    it "delegate write" do
      @account.old = 'new'
      assert_equal 'new', @account.settings.hep
      assert_equal 'new', @account.old
    end
  end

  describe "changed?" do
    it "not add a property" do
      @account.old_changed?
      assert_equal 0, @account.settings.size
    end

    it "not be changed" do
      assert_equal false, @account.old_changed?
    end

    it "be changed with new value" do
      @account.old = "new"
      assert_equal true, @account.old_changed?
    end

    it "not be changed with default value" do
      @account.old = @default
      assert_equal false, @account.old_changed?
    end
  end

  describe "before_type_case" do
    it "not add a property" do
      @account.old_before_type_cast
      assert_equal 0, @account.settings.size
    end

    it "return default" do
      assert_equal @default, @account.old_before_type_cast
    end

    it "return setting" do
      @account.old = "new"
      assert_equal "new", @account.old_before_type_cast
    end
  end
end
