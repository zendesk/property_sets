# frozen_string_literal: true

module PropertySets
  class ValueReader
    # Build a new value reader for a property set record.
    #
    # @param property_name [Symbol]
    # @param assoc_instance [ActiveRecord::Base]
    # @param assoc_class [Class]
    #
    def initialize(property_name:, assoc_instance:, assoc_class:)
      @name = property_name
      @instance = assoc_instance
      @assoc_class = assoc_class
    end

    # Returns the value of the property that is part of a property set.
    # It takes into account the property type (e.g. whether it's serialized)
    # and performs the required casting and parsing.
    #
    # @return [Object, nil]
    #
    def read
      serialized = property_serialized?

      if @instance
        @instance.value_serialized = serialized
        PropertySets::Casting.read(type, @instance.value)
      else
        value = @assoc_class.default(@name)
        if serialized
          PropertySets::Casting.deserialize(value)
        else
          PropertySets::Casting.read(type, value)
        end
      end
    end

    def property_serialized?
      type == :serialized
    end

    def type
      @type ||= @assoc_class.type(@name)
    end
  end
end
