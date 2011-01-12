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

  create_table "accounts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
