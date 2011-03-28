require 'action_view'

module ActionView
  module Helpers
    class FormBuilder
      class PropertySetFormBuilderProxy
        attr_accessor :property_set
        attr_accessor :template
        attr_accessor :object_name

        def initialize(property_set, template, object_name)
          self.property_set = property_set
          self.template     = template
          self.object_name  = object_name
        end

        def check_box(property, options = {}, checked_value = "1", unchecked_value = "0")
          options = prepare_options(property, options) do |properties|
            properties.send("#{property}?")
          end
          template.check_box(object_name, property, options, checked_value, unchecked_value)
        end

        def radio_button(property, checked_value = "1", options = {})
          options = prepare_options(property, options) do |properties|
            properties.send("#{property}") == checked_value.to_s
          end
          template.radio_button(object_name, property, checked_value, options)
        end

        def hidden_field(property, options = {})
          template.hidden_field(object_name, property, prepare_id_name(property, options))
        end

        def prepare_id_name(property, options)
          throw "Invalid options type #{options.inspect}" unless options.is_a?(Hash)

          instance = template.instance_variable_get("@#{object_name}")

          throw "No @#{object_name} in scope" if instance.nil?
          throw "The property_set_check_box only works on models with property set #{property_set}" unless instance.respond_to?(property_set)

          options[:id]     ||= "#{object_name}_#{property_set}_#{property}"
          options[:name]     = "#{object_name}[#{property_set}][#{property}]"
          options[:object]   = instance

          options
        end

        def prepare_options(property, options, &block)
          options = prepare_id_name(property, options)
          options[:checked] = yield(options[:object].send(property_set))
          options
        end
      end

      def property_set(identifier)
        PropertySetFormBuilderProxy.new(identifier, @template, @object_name)
      end

    end
  end
end