require 'active_record'
require 'property_sets/casting'

module PropertySets
  module ActiveRecordExtension
    module ClassMethods

      def property_set(association, options = {}, &block)
        unless include?(PropertySets::ActiveRecordExtension::InstanceMethods)
          self.send(:prepend, PropertySets::ActiveRecordExtension::InstanceMethods)
          cattr_accessor :property_set_index
          self.property_set_index = []
        end

        raise "Invalid association name, letters only" unless association.to_s =~ /[a-z]+/
        self.property_set_index << association

        property_class = PropertySets.ensure_property_set_class(
          association,
          options.delete(:owner_class_name) || self.name
        )
        property_class.instance_eval(&block)

        hash_opts = {:class_name => property_class.name, :autosave => true, :dependent => :destroy}.merge(options)

        silence_warnings do
          has_many association, hash_opts do
            include PropertySets::ActiveRecordExtension::AssociationExtensions

            property_class.keys.each do |key|
              raise "Invalid property key #{key}" if self.respond_to?(key)

              # Reports the coerced truth value of the property
              define_method "#{key}?" do
                type  = property_class.type(key)
                value = lookup_value(type, key)
                ![ "false", "0", "", "off", "n" ].member?(value.to_s.downcase)
              end

              # Returns the value of the property
              define_method "#{key}" do
                type = property_class.type(key)
                lookup_value(type, key)
              end

              # Assigns a new value to the property
              define_method "#{key}=" do |value|
                instance = lookup(key)
                instance.value = PropertySets::Casting.write(property_class.type(key), value)
                instance.value
              end

              define_method "#{key}_record" do
                lookup(key)
              end
            end

            define_method :property_serialized? do |key|
              property_class.type(key) == :serialized
            end
          end
        end
      end
    end

    module AssociationExtensions
      # Accepts an array of names as strings or symbols and returns a hash.
      def get(keys = [])
        property_keys = if keys.empty?
          association_class.keys
        else
          association_class.keys & keys.map(&:to_s)
        end

        property_pairs = property_keys.map do |name|
          value = lookup_value(association_class.type(name), name)
          [name, value]
        end.flatten(1)
        HashWithIndifferentAccess[*property_pairs]
      end

      # Accepts a name value pair hash { :name => 'value', :pairs => true } and builds a property for each key
      def set(property_pairs, with_protection = false)
        property_pairs.keys.each do |name|
          record = lookup(name)
          if with_protection && record.protected?
            logger.warn("Someone tried to update the protected #{name} property to #{property_pairs[name]}")
          else
            send("#{name}=", property_pairs[name])
          end
        end
      end

      def save(*args)
        each { |p| p.save(*args) }
      end

      def save!(*args)
        each { |p| p.save!(*args) }
      end

      def protected?(arg)
        lookup(arg).protected?
      end

      def enable(arg)
        send("#{arg}=", "1")
      end

      def disable(arg)
        send("#{arg}=", "0")
      end

      def build_default(arg)
        build(:name => arg.to_s, :value => raw_default(arg))
      end

      def lookup_without_default(arg)
        detect { |property| property.name.to_sym == arg.to_sym }
      end

      def lookup_value(type, key)
        serialized = property_serialized?(key)

        if instance = lookup_without_default(key)
          instance.value_serialized = serialized
          PropertySets::Casting.read(type, instance.value)
        else
          value = default(key)
          if serialized
            PropertySets::Casting.deserialize(value)
          else
            PropertySets::Casting.read(type, value)
          end
        end
      end

      # The finder method which returns the property if present, otherwise a new instance with defaults
      def lookup(arg)
        instance   = lookup_without_default(arg)
        instance ||= build_default(arg)
        instance.value_serialized = property_serialized?(arg)

        owner = proxy_association.owner

        instance.send("#{owner_class_sym}=", owner) if owner.new_record?
        instance
      end

      # This finder method returns the property if present, otherwise a new instance with the default value.
      # It does not have the side effect of adding a new setting object.
      def lookup_or_default(arg)
        instance = lookup_without_default(arg)
        instance ||= association_class.new(:value => raw_default(arg))
        instance.value_serialized = property_serialized?(arg)
        instance
      end

      def association_class
        @association_class ||= proxy_association.klass
      end
    end

    module InstanceMethods
      def update_attributes(attributes)
        update_property_set_attributes(attributes)
        super
      end

      def update_attributes!(attributes)
        update_property_set_attributes(attributes)
        super
      end

      def update_property_set_attributes(attributes)
        if attributes && self.class.property_set_index.any?
          self.class.property_set_index.each do |property_set|
            if property_set_hash = attributes.delete(property_set)
              send(property_set).set(property_set_hash, true)
            end
          end
        end
      end
    end

  end
end

ActiveRecord::Base.extend PropertySets::ActiveRecordExtension::ClassMethods
