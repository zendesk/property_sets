require 'property_sets/property_set_model'
require 'property_sets/active_record_extension'
require 'property_sets/version'

begin
  require 'property_sets/action_view_extension'
rescue LoadError
end

if "#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}" == "6.1"
  ActiveRecord::Base.singleton_class.alias_method :connection_class_for_self, :connection_classes
end

module PropertySets
  def self.ensure_property_set_class(association, owner_class_name)
    const_name = "#{owner_class_name.demodulize}#{association.to_s.singularize.camelcase}"
    namespace = owner_class_name.deconstantize.safe_constantize || Object

    unless namespace.const_defined?(const_name, false)
      property_class = Class.new(parent_for_property_class(namespace, owner_class_name)) do
        include PropertySets::PropertySetModel::InstanceMethods
        extend  PropertySets::PropertySetModel::ClassMethods
      end

      namespace.const_set(const_name, property_class)

      property_class.owner_class = owner_class_name
      property_class.owner_assoc = association
    end

    namespace.const_get(const_name.to_s)
  end

  def self.parent_for_property_class(namespace, owner_class_name)
    owner_class = namespace.const_get(owner_class_name)

    owner_class.property_sets_connection_class || owner_class.connection_class_for_self
  rescue NameError
    ::ActiveRecord::Base
  end
end
