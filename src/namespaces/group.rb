
# frozen_string_literal: true

module Metalware
  module Namespaces
    class Group < HashMergerNamespace
      attr_reader :name

      private

      def hash_merger_input
        { groups: [name] }
      end

      def additional_dynamic_namespace
        { group: self }
      end
    end
  end
end
