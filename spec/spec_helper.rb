require 'bundler/setup'

require 'active_support'
require 'active_record'
require 'active_record/fixtures'

require 'property_sets'
require 'property_sets/delegator'
require 'support/database'
require 'support/account'
require 'support/thing'

require 'pry'

I18n.enforce_available_locales = false

# http://stackoverflow.com/questions/5490411/counting-the-number-of-queries-performed/43810063#43810063
module QueryAssertions
  def sql_queries(&block)
    queries = []
    counter = ->(*, payload) {
      queries << payload.fetch(:sql) unless ["CACHE", "SCHEMA"].include?(payload.fetch(:name))
    }

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)

    queries
  end

  def assert_sql_queries(expected, &block)
    queries = sql_queries(&block)
    expect(queries.count).to eq(expected), "Expected #{expected} queries, but found #{queries.count}:\n#{queries.join("\n")}"
  end
end

module ActiveRecord
  module Associations
    class CollectionProxy
      def scoping
        raise 'CollectionProxy delegates unknown methods to target (association_class) via method_missing, wrapping the call with `scoping`. Instead, call the method directly on the association_class!'
      end
    end
  end
end

RSpec.configure { |c| c.include QueryAssertions }
