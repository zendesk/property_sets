require 'active_support'

module PropertySets
  module PropertySetModel
    module InstanceMethods

      def false?
        [ "false", "0", "", "off", "n" ].member?(value.to_s.downcase)
      end

      def true?
        !false?
      end

      def enable
        update_attribute(:value, "1")
        self
      end

      def disable
        update_attribute(:value, "0")
        self
      end

      def protected?
        self.class.protected?(name.to_sym)
      end

      def value
        if value_serialized
          v = read_attribute(:value)
          @deserialized_value ||= PropertySets::Casting.deserialize(v)
        else
          super
        end
      end

      def value=(v)
        if value_serialized
          @deserialized_value = v
          write_attribute(:value, v.to_json)
        else
          super(v)
        end
      end

      def reload(*args, &block)
        @deserialized_value = nil
        super
      end

      def to_s
        value.to_s
      end

      attr_accessor :value_serialized

      private

      def validate_format_of_name
        if name.blank?
          errors.add(:name, :blank)
        elsif !name.is_a?(String) || name !~ /^([a-z0-9]+_?)+$/
          errors.add(:name, :invalid)
        end
      end

      def validate_length_of_serialized_data
        if value_serialized && self.read_attribute(:value).to_s.size > self.class.columns_hash["value"].limit
          errors.add(:value, :invalid)
        end
      end

      def coerce_value
        if value && !value_serialized
          self.value = value.to_s
        end
      end

      def owner_class_instance
        send(self.class.owner_class_sym)
      end
    end

    module ClassMethods
      def self.extended(base)
        base.validate        :validate_format_of_name
        base.validate        :validate_length_of_serialized_data
        base.before_create   :coerce_value
        base.attr_accessible :name, :value if ActiveRecord::VERSION::MAJOR == 3 || defined?(ProtectedAttributes)
      end

      def property(key, options = nil)
        @properties ||= HashWithIndifferentAccess.new
        @properties[key] = options
      end

      def keys
        @properties.keys
      end

      def default(key, owner=nil)
        PropertySets::Casting.read(type(key), raw_default(key, owner))
      end

      def raw_default(key, owner=nil)
        default_value = @properties[key].try(:[], :default)
        if default_value.is_a?(Proc)
          default_value = default_value.call(owner)
        end
        default_value
      end

      def type(key)
        @properties[key].try(:[], :type) || :string
      end

      def protected?(key)
        @properties[key].try(:[], :protected) || false
      end

      def owner_class=(owner_class_name)
        @owner_class_sym = owner_class_name.underscore.to_sym
        belongs_to              owner_class_sym
        validates_presence_of   owner_class_sym
        validates_uniqueness_of :name, :scope => owner_class_key_sym
        attr_accessible         owner_class_key_sym, owner_class_sym if ActiveRecord::VERSION::MAJOR == 3 || defined?(ProtectedAttributes)
      end

      def owner_assoc=(association)
        @owner_assoc = association
      end

      def owner_assoc
        @owner_assoc
      end

      def owner_class_sym
        @owner_class_sym
      end

      def owner_class_key_sym
        "#{owner_class_sym}_id".to_sym
      end
    end

  end
end
