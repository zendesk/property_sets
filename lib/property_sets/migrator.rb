module PropertySet
  module Migrator
    # Internal: Set up some alias methods for moving what was once a literal column on
    # accounts to a property_set table.
    #
    # Methodology:
    #
    # * on read, first look-aside to `property_set` table, use that value if exists,
    #   else fallback to column.
    # * on write, write to `property_set` table only.
    #
    # setname - the Symbol or String name of the `property_set` assocation to migrate to.
    # attrs   - a varg paramater where the values are either symbols keys or hashes mapping column
    #           names to property names
    #
    # Examples
    #
    #   # Migrate :mail_delimiter and :domain_whitelist to the :texts property set
    #   migrate_to_property_set :texts, :description, :bio
    #
    #   # Migrate :is_fuubar to the :settings property set, and rename it :open
    #   migrate_to_property_set :settings, :is_fuubar => :fuubar
    #
    def self.included(base)
      class << base
        attr_reader :migrated_to_property_set_attributes
      end
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
    end

    def save_migrated_properties_to_sets!
      self.class.migrated_to_property_set_attributes.each do |attr|
        # lookup from either property set or acccounts table, save to property set
        self.send("#{attr}=", self.send(attr))
      end

      self.settings.map(&:save!)
      self.texts.map(&:save!) if respond_to?(:texts)
    end

    module InstanceMethods
      # This is here to facilitate logging with an Arturo feature
      # in classic. Can be removed once this method is removed from
      # classic 2013-11-19 - edsinclair
      def log_migrated_attribute_read(method_name)
        yield if block_given?
      end
    end

    module ClassMethods

      def migrate_to_property_set(setname, *attrs)
        attr_hash = {}
        attrs.each do |attr|
          if attr.is_a?(Hash)
            attr.each do |k, v|
              attr_hash[k] = v
            end
          else
            attr_hash[attr.to_sym] = attr.to_sym
          end
        end

        @migrated_to_property_set_attributes ||= []
        @migrated_to_property_set_attributes += attr_hash.keys
        @migrated_to_property_set_attributes.uniq!

        attr_hash.each do |old_attr, new_attr|
          define_method(old_attr) do
            assoc = send(setname)

            # if migrating setting exists in property set, use that.  else use default.
            if assoc.lookup_without_default(new_attr)
              assoc.send(new_attr)
            else
              log_migrated_attribute_read(__method__) { read_attribute(old_attr) }
            end
          end

          define_method("#{old_attr}?") do
            assoc = send(setname)

            if assoc.lookup_without_default(new_attr)
              assoc.send("#{new_attr}?")
            else
              log_migrated_attribute_read(__method__) { query_attribute(old_attr.to_s) }
            end
          end

          define_method("#{old_attr}=") do |value|
            assoc = send(setname)

            assoc.send("#{new_attr}=", value)
          end

          define_method("#{old_attr}_changed?") do
            assoc = send(setname)

            setting = assoc.lookup_without_default(new_attr)
            if !setting
              false
            elsif setting.new_record?
              reflection = assoc.proxy_association
              setting_value = PropertySets::Casting.read(reflection.klass.type(new_attr), setting.value)
              setting_value != log_migrated_attribute_read(__method__) { read_attribute(old_attr) }
            else
              setting.value_changed?
            end
          end

          define_method("#{old_attr}_before_type_cast") do
            assoc = send(setname)

            setting = assoc.lookup_without_default(new_attr)
            if setting
              setting.value
            else
              log_migrated_attribute_read(__method__) { read_attribute_before_type_cast(old_attr.to_s) }
            end
          end
        end
      end
    end
  end
end
