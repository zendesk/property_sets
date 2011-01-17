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

      private

      def validate_format_of_name
        if name.blank?
          errors.add(:name, :blank)
        elsif !name.is_a?(String) || name !~ /^([a-z0-9]+_?)+$/
          errors.add(:name, :invalid)
        end
      end

      def coerce_value
        self.value = value.to_s unless value.nil?
      end

      def owner_class_instance
        send(self.class.owner_class_sym)
      end

      def update_owner_timestamp
        if owner_class_instance && !owner_class_instance.new_record? && owner_class_instance.updated_at < 1.second.ago
          owner_class_instance.update_attribute(:updated_at, Time.now)
        end
      end

      def reset_owner_association
        owner_class_instance.send(self.class.owner_assoc).reload
      end
    end

    module ClassMethods
      def self.extended(base)
        base.after_create  :reset_owner_association
        base.after_destroy :reset_owner_association
        base.validate      :validate_format_of_name
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

      def protected?(key)
        @properties[key] && !!@properties[key][:protected]
      end

      def owner_class=(owner_class)
        @owner_class_sym = owner_class.name.underscore.to_sym
        belongs_to              owner_class_sym
        validates_presence_of   owner_class_sym
        validates_uniqueness_of :name, :scope => owner_class_key_sym

        if owner_class.table_exists? && owner_class.column_names.include?("updated_at")
          before_create   :update_owner_timestamp
          before_destroy  :update_owner_timestamp
        end
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
