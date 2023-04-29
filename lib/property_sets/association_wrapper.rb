# frozen_string_literal: true

require "property_sets/casting"
require "property_sets/value_reader"

module PropertySets
  # A wrapper for the underlying has_many ActiveRecord association that represents
  # the property set. This class intercepts query methods that would be injected
  # into the association, and implements that interface contract with its own
  # implementation. Its goal is to provide a more lightweight form of DB access.
  #
  class AssociationWrapper
    # Build a new association wrapper for the property set.
    #
    # @param owner_instance [ActiveRecord::Base]
    # @param assoc_name [Symbol]
    # @param assoc_class [Class]
    # @param opts [Hash]
    #
    def initialize(owner_instance:, assoc_name:, assoc_class:, opts:)
      @owner_instance = owner_instance
      @assoc_name = assoc_name
      @assoc_class = assoc_class
      @opts = opts
      @loaded_records = {}
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    # Accepts an array of names as strings or symbols and returns a hash.
    #
    # @param keys [Array<Symbol, String>]
    # @return [HashWithIndifferentAccess]
    #
    def get(keys = [])
      property_keys = if keys.empty?
        @assoc_class.keys
      else
        @assoc_class.keys & keys.map(&:to_s)
      end

      property_pairs = property_keys.map do |name|
        value = _lookup_value(name)
        [name, value]
      end.flatten(1)

      HashWithIndifferentAccess[*property_pairs]
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    # Accepts a name value pair hash { :name => 'value', :pairs => true } and builds a property for each key
    #
    # @param property_pairs [Hash]
    # @param with_protection [Boolean]
    # @return [Array<Symbol]
    #
    def set(property_pairs, with_protection = false)
      property_pairs.keys.each do |name|
        record = lookup(name)
        if with_protection && record.protected?
          @assoc_class.logger.warn("Someone tried to update the protected #{name} property to #{property_pairs[name]}")
        else
          set_property(name, property_pairs[name])
        end
      end
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    def save(*args)
      @loaded_records.each do |prop_name, instance|
        instance.save(*args) if instance&.changed?
      end
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    def save!(*args)
      @loaded_records.each do |prop_name, instance|
        instance.save!(*args) if instance&.changed?
      end
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    def protected?(arg)
      lookup(arg).protected?
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    def enable(arg)
      set_property(arg, "1")
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    def disable(arg)
      set_property(arg, "0")
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    # Returns a record
    #
    def lookup_without_default(name)
      @loaded_records[name.to_sym] ||= underlying_association.find_by(name: name)
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    def lookup_value(_type, name)
      _lookup_value(name)
    end

    # The signature of the original `lookup_value` expects the property type, which
    # is not required with this implementation (it's retrieved in a different way).
    #
    def _lookup_value(name)
      PropertySets::ValueReader.new(
        property_name: name,
        assoc_instance: lookup_without_default(name),
        assoc_class: @assoc_class
      ).read
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    def lookup(name)
      instance = lookup_without_default(name)

      instance ||= underlying_association.build(
        name: name.to_sym,
        value: @assoc_class.raw_default(name)
      )

      instance.value_serialized = property_serialized?(name)
      instance.public_send("#{@assoc_class.owner_class_sym}=", @owner_instance) if @owner_instance.new_record?

      @loaded_records[name.to_sym] ||= instance

      instance
    end

    # Adopted from `PropertySets::ActiveRecordExtension::AssociationExtensions`.
    #
    # This finder method returns the property if present, otherwise a new instance with the default value.
    # It does not have the side effect of adding a new setting object.
    #
    # Among the "lookup" methods, this alone is not used internally in the gem.
    # It's part on the undocumented public API, and application code can make
    # use of it to try to fetch a property record or an unpersisted default
    # record, _without adding it to the association collection_, which means
    # that the returned default will not risk to be saved.
    #
    def lookup_or_default(name)
      instance = lookup_without_default(arg)
      instance ||= @assoc_class.new(value: @assoc_class.raw_default(arg))
      instance.value_serialized = property_serialized?(arg)
      instance
    end

    # Required to make the change-tracking Delegator methods work.
    #
    def loaded?
      @loaded_records.any?
    end

    private

    # The main entry point for this class.
    # It's meant to intercept attempts to access the property set collection by
    # key (property name), and in that case try to only load the relevant records.
    #
    # It delegates anything else to the underlying association.
    #
    def method_missing(meth_name, *meth_args, &block)
      prop_name, suffix = recognize_property_method(meth_name)

      if prop_name
        handle_property_access(prop_name, suffix, meth_args)
      else
        # Delegate to the underlying association.
        underlying_association.public_send(meth_name, *meth_args, &block)
      end
    end

    # The underlying ActiveRecord has_many association.
    #
    def underlying_association
      @underlying_association ||= @owner_instance.public_send(
        "#{@assoc_name}_without_wrapper", **@opts
      )
    end

    def properties
      @properties ||= @assoc_class.properties
    end

    def is_property?(name)
      properties.include? name
    end

    def check_predicate(name)
      !PropertySets::Casting::FALSE.include?(
        lookup_value(nil, name).to_s.downcase
      )
    end

    def set_property(name, value)
      instance = lookup(name)
      instance.value = PropertySets::Casting.write(@assoc_class.type(name), value)

      @loaded_records[name.to_sym] = instance

      instance.value
    end

    def handle_property_access(name, suffix, args)
      case suffix
      when "="      then set_property(name, args[0])
      when "?"      then check_predicate(name)
      when "record" then lookup(name)
      when nil      then _lookup_value(name)
      else
        raise NoMethodError, "unrecognized property access (#{name}#{suffix})"
      end
    end

    def respond_to_missing?(meth_name, include_private = false)
      underlying_association.respond_to?(meth_name) or super
    end

    PROPERTY_ACCESS_REGEX = %r{\A(\w+)(\=|\?)?\z}.freeze
    PROPERTY_RECORD_REGEX = %r{_record\z}.freeze

    # Takes in a method selector and checks whether it's a property set access
    # attempt. If it is, it returns the property name and the method suffix, e.g.
    # "?", "=" or "_record." A missing suffix means that the caller wants to read
    # the property set value for this key.
    #
    def recognize_property_method(meth)
      md = PROPERTY_ACCESS_REGEX.match(meth.to_s)
      return nil unless md

      prop_name, suffix = md[1], md[2]
      return nil if prop_name.nil?

      if suffix.nil? && PROPERTY_RECORD_REGEX === prop_name
        suffix = "record"
        prop_name.sub!(PROPERTY_RECORD_REGEX, "")
      end

      return nil unless is_property?(prop_name)

      [prop_name, suffix]
    end

    def property_serialized?(name)
      @assoc_class.type(name) == :serialized
    end
  end
end
