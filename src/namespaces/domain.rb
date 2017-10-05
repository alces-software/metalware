
# frozen_string_literal: true

module Metalware
  module Namespaces
    class Domain < HashMergerNamespace
      private

      def hash_merger_input
        {}
      end

      def additional_dynamic_namespace
        {}
      end
    end
  end
end
