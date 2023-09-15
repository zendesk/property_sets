require "json"

module PropertySets
  module Casting
    FALSE_VALUES = ["false", "0", "", "off", "n"]

    class << self
      def read(type, value)
        return nil if value.nil?

        case type
        when :string
          value
        when :datetime
          Time.parse(value).in_time_zone
        when :float
          value.to_f
        when :integer
          value.to_i
        when :boolean
          !false?(value)
        when :serialized
          # deserialization happens in the model
          value
        end
      end

      def write(type, value)
        return nil if value.nil?

        case type
        when :datetime
          if value.is_a?(String)
            value
          else
            value.in_time_zone("UTC").to_s
          end
        when :serialized
          # write the object directly.
          value
        when :boolean
          false?(value) ? "0" : "1"
        else
          value.to_s
        end
      end

      def deserialize(value)
        return nil if value.nil? || value == "null"
        JSON.parse(value)
      end

      private

      def false?(value)
        FALSE_VALUES.include?(value.to_s.downcase)
      end
    end
  end
end
