# setup database
require 'active_record'
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::ERROR

mysql = URI(ENV['MYSQL_URL'] || 'mysql://root@127.0.0.1:3306')

config = {
  :adapter  => RUBY_PLATFORM == "java" ? 'mysql' : 'mysql2',
  :database => 'property_sets_test',
  :username => mysql.user,
  :password => mysql.password,
  :host     => mysql.host,
  :port     => mysql.port
}

ActiveRecord::Base.establish_connection(config.merge(:database => nil))

# clear out everything
ActiveRecord::Base.connection.drop_database config[:database]
ActiveRecord::Base.connection.create_database config[:database], :charset => 'utf8', :collation => 'utf8_unicode_ci'

# connect and check
ActiveRecord::Base.establish_connection(config)
ActiveRecord::Base.connection.execute('select 1')

ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define(:version => 1) do
  create_table "account_settings", :force => true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index :account_settings, [ :account_id, :name ], :unique => true

  create_table "account_texts", :force => true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index :account_texts, [ :account_id, :name ], :unique => true

  create_table "account_validations", :force => true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index :account_validations, [ :account_id, :name ], :unique => true

  create_table "account_typed_data", :force => true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index :account_typed_data, [ :account_id, :name ], :unique => true

  create_table "account_benchmark_settings", :force => true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index :account_benchmark_settings, [ :account_id, :name ], :unique => true

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
