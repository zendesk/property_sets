require File.expand_path(File.dirname(__FILE__) + "/../test/helper")

class Account < ActiveRecord::Base
  # Benchmark reading from an object with many settings when:
  # 1. Settings are undefined and use the default value (empty)
  # 2. Settings are defined and use the database value (fully defined)

  # This is a fairly realastic example of an object that has a lot of settings
  property_set :benchmark_settings do
    # 30 simple objects
    10.times do |i|
      property "float_prop_#{i}", :type => :float, :default => 3.1415
      property "int_prop_#{i}", :type => :integer, :default => 22
      property "string_prop_#{i}", :type => :string, :default => "Sausalito, CA"
    end

    # 10 complex
    5.times do |i|
      property "datetime_prop_#{i}", :type => :datetime, :default => Time.now.to_s
      property "serialized_prop_#{i}", :type => :serialized, :default => {"Hello" => "There"}
    end

    # 60 booleans
    60.times do |i|
      property "boolean_prop_#{i}", :type => :boolean, :default => true
    end
  end
end

class BenchmarkRead < ActiveSupport::TestCase
  context "property sets" do
    setup do
      @account = Account.create(:name => "Name")
    end

    should "benchmark fully defined settings" do
      # Most settings are defined and will come from the database
      @account.benchmark_settings.keys.each do |key|
        @account.benchmark_settings.build_default(key)
      end
      @account.save!
      @account.reload
      assert_equal 100, @account.benchmark_settings.count

      GC.start
      full_timing = Benchmark.ms do
        1_000.times do
          read_settings(@account)
        end
      end
      puts "Reading fully defined settings: #{full_timing}ms"
    end

    should "benchmark defaults" do
      assert_equal 0, @account.benchmark_settings.count
      # Most settings are undefined and will use the default value
      GC.start
      empty_timing = Benchmark.ms do
        1_000.times do
          read_settings(@account)
        end
      end
      puts "Reading empty settings: #{empty_timing}ms"
    end
  end

  def read_settings(account)
    account.benchmark_settings.float_prop_1
    account.benchmark_settings.int_prop_1
    account.benchmark_settings.string_prop_1
    account.benchmark_settings.datetime_prop_1
    account.benchmark_settings.boolean_prop_20?
    account.benchmark_settings.boolean_prop_30?
    account.benchmark_settings.boolean_prop_40?
    account.benchmark_settings.boolean_prop_50?
  end
end
