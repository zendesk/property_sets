module ActionView
  module Helpers
    def setting_check_box(model_name, method, options = {}, checked_value = "1", unchecked_value = "0")
      the_model = @template.instance_variable_get("@#{model_name}")
      throw "No @#{model_name} in scope" if the_model.nil?
      throw "The setting_check_box only works on models with settings" unless the_model.respond_to?(:settings)
      options[:checked] = the_model.settings.send("#{method}?")
      options[:id]    ||= "#{model_name}_settings_#{method}"
      options[:name]    = "#{model_name}[settings][#{method}]"
      @template.check_box(model_name, "settings_#{method}", options, checked_value, unchecked_value)
    end

    class FormBuilder
      def setting_check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
        @template.setting_check_box(@object_name, method, objectify_options(options), checked_value, unchecked_value)
      end
    end
  end
end