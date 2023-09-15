require "active_support"

module PropertySets
  module PropertySetModel
    # https://dev.mysql.com/doc/refman/5.6/en/storage-requirements.html
    COLUMN_TYPE_LIMITS = {
      "tinyblob"   => 255,        # 2^8 - 1
      "tinytext"   => 255,
      "blob"       => 65535,      # 2^16 - 1
      "text"       => 65535,
      "mediumblob" => 16777215,   # 2^24 - 1
      "mediumtext" => 16777215,
      "longblob"   => 4294967295, # 2^32 - 1
      "longtext"   => 4294967295,
    }.freeze

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
        if value_serialized && read_attribute(:value).to_s.size > value_column_limit
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

      def value_column_limit
        column = self.class.columns_hash.fetch("value")

        # use sql_type because type returns :text for all text types regardless of length
        column.limit || COLUMN_TYPE_LIMITS.fetch(column.sql_type)
      end
    end

    module ClassMethods
      def self.extended(base)
        base.validate        :validate_format_of_name
        base.validate        :validate_length_of_serialized_data
        base.before_create   :coerce_value
        base.attr_accessible :name, :value if defined?(ProtectedAttributes)
      end

      def properties
        @properties ||= HashWithIndifferentAccess.new
      end

      def property(key, options = nil)
        properties[key] = options
      end

      def keys
        properties.keys
      end

      def default(key)
        PropertySets::Casting.read(type(key), raw_default(key))
      end

      def raw_default(key)
        properties[key].try(:[], :default)
      end

      def type(key)
        properties[key].try(:[], :type) || :string
      end

      def protected?(key)
        properties[key].try(:[], :protected) || false
      end

      def owner_class=(owner_class_name)
        @owner_class_sym = owner_class_name.to_s.demodulize.underscore.to_sym

        belongs_to              owner_class_sym, class_name: owner_class_name
        validates_presence_of   owner_class_sym, class_name: owner_class_name
        validates_uniqueness_of :name, :scope => owner_class_key_sym, :case_sensitive => false
        attr_accessible         owner_class_key_sym, owner_class_sym if defined?(ProtectedAttributes)
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
