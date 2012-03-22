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

      def to_s
        value.to_s
      end

      attr_accessor :validate_serialization

      private

      def validate_format_of_name
        if name.blank?
          errors.add(:name, :blank)
        elsif !name.is_a?(String) || name !~ /^([a-z0-9]+_?)+$/
          errors.add(:name, :invalid)
        end
      end

      def validate_length_of_serialized_data
        if validate_serialization && self.class.columns_hash["value"].limit < self.value.size
          errors.add(:value, :invalid)
        end
      end

      def coerce_value
        self.value = value.to_s unless value.nil?
      end


      def owner_class_instance
        send(self.class.owner_class_sym)
      end
    end

    module ClassMethods
      def self.extended(base)
        base.validate      :validate_format_of_name
        base.validate      :validate_length_of_serialized_data
        base.before_create :coerce_value
      end

      def property(key, options = nil)
        @properties ||= {}
        @properties[key] = options
      end

      def keys
        @properties.keys
      end

      def default(key)
        @properties[key] && @properties[key].key?(:default) ? @properties[key][:default] : nil
      end

      def type(key)
        @properties[key] && @properties[key].key?(:type) ? @properties[key][:type] : :string
      end

      def protected?(key)
        @properties[key] && !!@properties[key][:protected]
      end

      def owner_class=(owner_class)
        @owner_class_sym = owner_class.name.underscore.to_sym
        belongs_to              owner_class_sym
        validates_presence_of   owner_class_sym
        validates_uniqueness_of :name, :scope => owner_class_key_sym
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
