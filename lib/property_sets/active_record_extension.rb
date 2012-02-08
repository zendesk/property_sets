require 'property_sets/casting'

module PropertySets
  module ActiveRecordExtension
    module ClassMethods

      def property_set(association, &block)
        unless include?(PropertySets::ActiveRecordExtension::InstanceMethods)
          self.send(:include, PropertySets::ActiveRecordExtension::InstanceMethods)
          cattr_accessor :property_set_index
          self.property_set_index = []
        end

        raise "Invalid association name, letters only" unless association.to_s =~ /[a-z]+/
        self.property_set_index << association

        property_class = PropertySets.ensure_property_set_class(association, self)
        property_class.instance_eval(&block)

        has_many association, :class_name => property_class.name, :autosave => true, :dependent => :destroy do

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

          property_class.keys.each do |key|
            raise "Invalid property key #{key}" if self.respond_to?(key)

            # Reports the coerced truth value of the property
            define_method "#{key}?" do
              lookup_or_default(key).true?
            end

            # Returns the value of the property
            define_method "#{key}" do
              PropertySets::Casting.read(property_class.type(key), lookup(key).value)
            end

            # Assigns a new value to the property
            define_method "#{key}=" do |value|
              instance = lookup(key)
              instance.value = PropertySets::Casting.write(property_class.type(key), value)
            end

            define_method "#{key}_record" do
              lookup(key)
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
            build(:name => arg.to_s, :value => default(arg))
          end

          def lookup_without_default(arg)
            detect { |property| property.name.to_sym == arg.to_sym }
          end

          # The finder method which returns the property if present, otherwise a new instance with defaults
          def lookup(arg)
            instance   = lookup_without_default(arg)
            instance ||= build_default(arg)

            if ActiveRecord::VERSION::MAJOR == 3
              owner = proxy_association.owner
            else
              owner = @owner
            end

            instance.send("#{owner_class_sym}=", owner) if owner.new_record?
            instance
          end

          # This finder method returns the property if present, otherwise a new instance with the default value.
          # It does not have the side effect of adding a new setting object.
          def lookup_or_default(arg)
            instance   = detect { |property| property.name.to_sym == arg.to_sym }
            instance ||= begin
              if ActiveRecord::VERSION::MAJOR == 3
                association_class = proxy_association.klass
              else
                association_class = @reflection.klass
              end
              association_class.new(:value => default(arg))
            end
          end
        end
      end
    end

    module InstanceMethods
      def self.included(base)
        base.alias_method_chain :update_attributes, :property_sets
        base.alias_method_chain :update_attributes!, :property_sets
      end

      def update_attributes_with_property_sets(attributes)
        update_property_set_attributes(attributes)
        update_attributes_without_property_sets(attributes)
      end

      def update_attributes_with_property_sets!(attributes)
        update_property_set_attributes(attributes)
        update_attributes_without_property_sets!(attributes)
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
