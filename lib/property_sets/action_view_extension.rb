require 'action_view'

module ActionView
  module Helpers
    class FormBuilder
      class PropertySetFormBuilderProxy
        attr_reader :property_set, :template, :object_name, :object

        def initialize(property_set, template, object_name, object)
          @property_set = property_set
          @template     = template
          @object_name  = object_name
          @object       = object
        end

        def check_box(property, options = {}, checked_value = "1", unchecked_value = "0")
          options = prepare_options(property, options) do |properties|
            properties.send("#{property}?")
          end
          template.check_box(object_name, property, options, checked_value, unchecked_value)
        end

        def radio_button(property, checked_value = "1", options = {})
          options[:id] ||= "#{object_name}_#{property_set}_#{property}_#{checked_value}"
          options = prepare_options(property, options) do |properties|
            properties.send("#{property}") == checked_value.to_s
          end
          template.radio_button(object_name, property, checked_value, options)
        end

        def text_field(property, options = {})
          template.text_field(object_name, property, prepare_id_name(property, options))
        end

        def hidden_field(property, options = {})
          options = prepare_id_name(property, options)
          unless options.keys.include?(:value)
            options[:value] = cast_boolean(options[:object].send(property_set).send(property)) 
          end
          template.hidden_field(object_name, property, options)
        end

        def select(property, choices, options = {}, html_options = {})
          options = prepare_id_name(property, options)
          current_value = options[:object].send(property_set).send(property)
          template.select("#{object_name}[#{property_set}]", property, choices, { :selected => current_value }, html_options )
        end

        private

        def prepare_id_name(property, options)
          throw "Invalid options type #{options.inspect}" unless options.is_a?(Hash)

          options.clone.tap do |prepared_options|
            prepared_options[:object]   = object || fetch_target_object
            prepared_options[:id]     ||= "#{object_name}_#{property_set}_#{property}"
            prepared_options[:name]     = "#{object_name}[#{property_set}][#{property}]"
          end
        end

        def fetch_target_object
          instance = template.instance_variable_get("@#{object_name}")

          throw "No @#{object_name} in scope" if instance.nil?
          throw "The property_set_check_box only works on models with property set #{property_set}" unless instance.respond_to?(property_set)

          instance
        end

        def prepare_options(property, options, &block)
          options = prepare_id_name(property, options)
          options[:checked] = yield(options[:object].send(property_set))
          options
        end

        def cast_boolean(value)
          case value
          when TrueClass  then '1'
          when FalseClass then '0'
          else value
          end
        end

      end

      def property_set(identifier)
        PropertySetFormBuilderProxy.new(identifier, @template, object_name, object)
      end

    end
  end
end
