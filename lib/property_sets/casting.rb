require 'json'

module PropertySets
  module Casting

    def self.read(type, value)
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
          ![ "false", "0", "", "off", "n" ].member?(value.to_s.downcase)
        when :serialized
          # deserialization happens in the model
          value
      end
    end

    def self.write(type, value)
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
        else
          value.to_s
      end
    end

  end
end
