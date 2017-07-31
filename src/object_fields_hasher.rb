
# frozen_string_literal: true

module Metalware
  module ObjectFieldsHasher
    IGNORED_METHODS = Object.instance_methods + [:to_h, :to_json]

    class << self
      def hash_object(object, **overrides)
        unique_object_methods(object).map do |field|
          field_getter = overrides[field] || field
          value = object.send(field_getter)
          [field, value]
        end.to_h
      end

      private

      def unique_object_methods(object)
        object.class.instance_methods - IGNORED_METHODS
      end
    end
  end
end
