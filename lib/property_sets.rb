require 'property_sets/property_set_model'
require 'property_sets/active_record_extension'
require 'property_sets/action_view_extension'

module PropertySets
  VERSION = "0.7.2"

  def self.ensure_property_set_class(association, owner_class)
    const_name = "#{owner_class.name}#{association.to_s.singularize.capitalize}".to_sym
    unless Object.const_defined?(const_name)
      property_class = Object.const_set(const_name, Class.new(ActiveRecord::Base))
      property_class.class_eval do
        include PropertySets::PropertySetModel::InstanceMethods
        extend  PropertySets::PropertySetModel::ClassMethods
      end

      property_class.owner_class = owner_class
      property_class.owner_assoc = association
    end
    Object.const_get(const_name)
  end
end
