
# frozen_string_literal: true

module Metalware
  module Namespaces
    class Group < HashMergerNamespace
      def initialize(alces, name, index:)
        @index = index
        super(alces, name)
      end

      attr_reader :name, :index

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
