module PropertySets
  module Delegator
    # methods for moving what was once a literal column on
    # to a property_set table.
    #
    # delegates read, write and query methods to the property record or the property default
    #
    # Examples
    #
    #   # Migrate :is_open to the :settings property set, and rename it :open,
    #   # and migrate :same to property set :same
    #   include PropertySets::Delegator
    #   delegate_to_property_set :settings, :is_open => :open, :same => :same
    #
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def delegate_to_property_set(setname, mappings)
        raise "Second argument must be a Hash" unless mappings.is_a?(Hash)

        @delegated_property_set_attributes ||= []

        mappings.each do |old_attr, new_attr|
          self.delegated_property_set_attributes << old_attr.to_s
          if ActiveRecord.version < Gem::Version.new("5.0")
            attribute old_attr, ActiveRecord::Type::Value.new
          else
            attribute old_attr, ActiveModel::Type::Value.new
          end
          define_method(old_attr) {
            association = send(setname)
            type = association.association_class.type(new_attr)
            association.lookup_value(type, new_attr)
          }
          alias_method "#{old_attr}_before_type_cast", old_attr
          define_method("#{old_attr}?") { send(setname).send("#{new_attr}?") }
          define_method("#{old_attr}=") do |value|
            attribute_will_change!(old_attr) if old_attr != value && !defined?(super)
            send(setname).send("#{new_attr}=", value)
            super(value) if defined?(super)
          end

          define_method("#{old_attr}_changed?") do
            collection_proxy = send(setname)
            return false unless collection_proxy.loaded?
            setting = collection_proxy.lookup_without_default(new_attr)

            if !setting
              false # Nothing has been set which means that the attribute hasn't changed
            elsif setting.new_record?
              collection_proxy.association_class.default(new_attr) != setting.value
            else
              setting.value_changed?
            end
          end
        end

        # These are not database columns and should not be included in queries but
        # using the attributes API is the only way to track changes in the main model
        if respond_to?(:user_provided_columns)
          self.user_provided_columns.reject!{|k,_| @delegated_property_set_attributes.include?(k.to_s) }
        end
      end

      def delegated_property_set_attributes
        @delegated_property_set_attributes
      end
    end
  end
end
