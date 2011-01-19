require 'action_view'
require 'delegate'

module ActionView
  module Helpers
    # property_set_check_box(:account, :property_association, :property_key, options)
    def property_set_check_box(model_name, property_set, property, options = {}, checked_value = "1", unchecked_value = "0")
      the_model = @template.instance_variable_get("@#{model_name}")

      throw "No @#{model_name} in scope" if the_model.nil?
      throw "The property_set_check_box only works on models with property set #{property_set}" unless the_model.respond_to?(property_set)

      options[:checked] = the_model.send(property).send("#{method}?")
      options[:id]    ||= "#{model_name}_property_sets_#{property_set}_#{method}"
      options[:name]    = "#{model_name}[property_sets][#{property_set}][#{method}]"
      @template.check_box(model_name, "property_sets_#{property_set}_#{method}", options, checked_value, unchecked_value)
    end
  end

  class FormBuilder
    class PropertySetFormBuilderProxy < Delegator
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

    def property_set(identifier)
      PropertySetFormBuilderProxy.new(identifier, self)
    end

    def property_set_check_box(property_set, property, options, checked_value, unchecked_value)
      @template.property_set_check_box(@object_name, property_set, property, objectify_options(options), checked_value, unchecked_value)
    end
  end
end

