require 'delegate'

module PropertySets
  class FormBuilderProxy < Delegator
    attr_accessor :builder
    attr_accessor :property_set

    def initialize(property_set, builder)
      self.property_set = property_set
      self.builder      = builder
    end

    def __getobj__
      builder
    end

    def check_box(property, options = {}, checked_value = "1", unchecked_value = "0")
      builder.property_set_check_box(property_set, property, options, checked_value, unchecked_value)
    end
  end
end

