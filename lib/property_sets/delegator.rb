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

        mappings.each do |old_attr, new_attr|
          if ActiveRecord.version < Gem::Version.new("5.0")
            attribute old_attr, ActiveRecord::Type::Value.new
          else
            attribute old_attr, ActiveModel::Type::Value.new
          end
          define_method(old_attr) { send(setname).send(new_attr) }
          alias_method "#{old_attr}_before_type_cast", old_attr
          define_method("#{old_attr}?") { send(setname).send("#{new_attr}?") }
          define_method("#{old_attr}=") do |value|
            send(setname).send("#{new_attr}=", value)
            super(value)
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
      end
    end
  end
end
