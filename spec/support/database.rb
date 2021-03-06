# setup database
require 'active_record'
ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.logger.level = Logger::ERROR

config = {
  :adapter  => "sqlite3",
  :database => ":memory:",
}

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

  create_table "account_tiny_texts", :force => true do |t|
    t.integer  "account_id"
    t.string   "name"
    t.text     "value",      :limit => (2**8 - 1)
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index :account_tiny_texts, [ :account_id, :name ], :unique => true

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "things", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "thing_settings", :force => true do |t|
    t.integer  "thing_id"
    t.string   "name"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index :thing_settings, [ :thing_id, :name ], :unique => true
end
