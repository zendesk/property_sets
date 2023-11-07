# frozen_string_literal: true

config = {
  :test => {
    :test_database => {
      :adapter  => "sqlite3",
      :database => ":memory:",
    },
  }
}

ActiveRecord::Base.configurations = config
