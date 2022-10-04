require 'active_record'
require 'property_sets/association_wrapper'
require 'property_sets/casting'
require 'property_sets/value_reader'
require 'set'

module PropertySets
  module ActiveRecordExtension
    module ClassMethods

      RAILS6 = ActiveRecord::VERSION::MAJOR >= 6

      def property_set(association, options = {}, &block)
        unless include?(PropertySets::ActiveRecordExtension::InstanceMethods)
          self.send(:prepend, PropertySets::ActiveRecordExtension::InstanceMethods)
          cattr_accessor :property_set_index
          self.property_set_index = Set.new
        end

        raise "Invalid association name, letters only" unless association.to_s =~ /[a-z]+/
        exists = property_set_index.include?(association)

        self.property_set_index << association

        # eg AccountSetting - this IS idempotent
        property_class = PropertySets.ensure_property_set_class(
          association,
          options.delete(:owner_class_name) || self.name
        )

        # eg property :is_awesome
        property_class.instance_eval(&block) if block

        tb_name = options.delete :table_name
        property_class.table_name = tb_name if tb_name

        hash_opts = {
          :class_name => property_class.name,
          :autosave => true,
          :dependent => :destroy,
          :inverse_of => self.name.underscore.to_sym,
        }.merge(options)

        # TODO: should check options are compatible? warn? raise?
        reflection = self.reflections[association.to_s] # => ActiveRecord::Reflection::HasManyReflection
        reflection.options.merge! options if reflection && !options.empty?

        unless exists then # makes has_many idempotent...
          has_many association, **hash_opts do
            # keep this damn block! -- creates association_module below
          end

          # Inject our association wrapper so that we can control how the association
          # is accessed and loaded from the DB. This allows us to not load the entire
          # dataset from the DB when we only care about a single property set entry.
          #
          # Alias the normal has_many association method.
          #
          alias_method "#{association}_without_wrapper", association
          #
          # An ivar to cache the association wrapper. This has to be scoped with the
          # association name in order to support multiple uses of property sets
          # within the same AR model.
          #
          association_wrapper_memo_name = prop_set_assoc_wrapper_memo_name(association)
          #
          # Redefine the association method.
          # The AssociationProxy will use the original (aliased) association
          # method when required.
          #
          define_method association do |**opts|
            memo = instance_variable_get(association_wrapper_memo_name) and return memo

            wrapper = PropertySets::AssociationWrapper.new(
              owner_instance: self,
              assoc_name: association,
              assoc_class: property_class,
              opts: opts
            )
            instance_variable_set(association_wrapper_memo_name, wrapper)

            wrapper
          end

          # To replicate ":autosave => true" on the has_many association.
          before_save -> do
            public_send(association).save
          end
        end

        # Open the association module defined with the has_many declaration (above)
        # and define custom accessors.

        # eg 5: AccountSettingsAssociationExtension
        # eg 6: Account::SettingsAssociationExtension

        # stolen/adapted from AR's collection_association.rb #define_extensions

        module_name = "#{association.to_s.camelize}AssociationExtension"
        module_name = name.demodulize + module_name unless RAILS6

        target = RAILS6 ? self : self.parent
        association_module = target.const_get module_name

        association_module.module_eval do
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


      def prop_set_assoc_wrapper_memo_name(association)
        "@prop_set_assoc_wrapper_#{association}"
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
            association_class.logger.warn("Someone tried to update the protected #{name} property to #{property_pairs[name]}")
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
        build(:name => arg.to_s, :value => association_class.raw_default(arg))
      end

      def lookup_without_default(arg)
        detect { |property| property.name.to_sym == arg.to_sym }
      end

      def lookup_value(_type, key)
        instance = lookup_without_default(key)
        PropertySets::ValueReader.new(
          property_name: key, assoc_instance: instance, assoc_class: association_class
        ).read
      end

      # The finder method which returns the property if present, otherwise a new instance with defaults
      def lookup(arg)
        instance   = lookup_without_default(arg)
        instance ||= build_default(arg)
        instance.value_serialized = property_serialized?(arg)

        owner = proxy_association.owner

        instance.send("#{association_class.owner_class_sym}=", owner) if owner.new_record?
        instance
      end

      # This finder method returns the property if present, otherwise a new instance with the default value.
      # It does not have the side effect of adding a new setting object.
      #
      # Among the "lookup" methods, this alone is not used internally in the gem.
      # It's part on the undocumented public API, and application code can make
      # use of it to try to fetch a property record or an unpersisted default
      # record, _without adding it to the association collection_, which means
      # that the returned default will not risk to be saved.
      #
      def lookup_or_default(arg)
        instance = lookup_without_default(arg)
        instance ||= association_class.new(:value => association_class.raw_default(arg))
        instance.value_serialized = property_serialized?(arg)
        instance
      end

      def association_class
        @association_class ||= proxy_association.klass
      end
    end

    module InstanceMethods
      def update(attributes)
        update_property_set_attributes(attributes)
        super
      end
      alias update_attributes update

      def update!(attributes)
        update_property_set_attributes(attributes)
        super
      end
      alias update_attributes! update!

      def update_property_set_attributes(attributes)
        if attributes && self.class.property_set_index.any?
          self.class.property_set_index.each do |property_set|
            if property_set_hash = attributes.delete(property_set)
              send(property_set).set(property_set_hash, true)
            end
          end
        end
      end

      def update_columns(attributes)
        if delegated_property_sets?
          attributes = attributes.reject{|k,_| self.class.delegated_property_set_attributes.include?(k.to_s) }
        end

        super attributes
      end

      # Remove all the memoized Association Proxies
      def reload(*args)
        clear_all_property_set_caches
        super(*args)
      end

      private

      def clear_all_property_set_caches
        self.class.property_set_index.each do |association|
          memo_ivar = self.class.prop_set_assoc_wrapper_memo_name(association)
          next unless instance_variable_defined?(memo_ivar)
          remove_instance_variable(memo_ivar)
        end
      end

      def delegated_property_sets?
        self.class.respond_to?(:delegated_property_set_attributes)
      end

      def attributes_for_create(attribute_names)
        super filter_delegated_property_set_attributes(attribute_names)
      end

      def attributes_for_update(attribute_names)
        super filter_delegated_property_set_attributes(attribute_names)
      end

      def filter_delegated_property_set_attributes(attribute_names)
        if delegated_property_sets?
          return attribute_names - self.class.delegated_property_set_attributes.to_a
        end
        attribute_names
      end
    end

  end
end

ActiveRecord::Base.extend PropertySets::ActiveRecordExtension::ClassMethods
