require 'active_support'
require 'active_record'
require 'property_sets'

yaml_config = "spec/support/database.yml"
ActiveRecord::Base.configurations = begin
                                      YAML.safe_load(IO.read(yaml_config), aliases: true)
                                    rescue ArgumentError
                                      YAML.safe_load(IO.read(yaml_config))
                                    end

class AbstractUnshardedModel < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: {writing: :unsharded_database, reading: :unsharded_database_replica}
end

class Account < AbstractUnshardedModel
  property_set :settings do
    property :type
  end
end

describe PropertySets do
  it "creates property_set model" do
    expect(defined?(AccountSetting)).to be_truthy
  end

  it "inherits from a correct class" do
    if ActiveRecord.gem_version >= Gem::Version.new("6.1")
      expect(AccountSetting.superclass).to be(AbstractUnshardedModel)
    else
      expect(AccountSetting.superclass).to be(ActiveRecord::Base)
    end
  end
end
