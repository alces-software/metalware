
# frozen_string_literal: true

module Metalware
  module Namespaces
    class Node < HashMergerNamespace
      attr_reader :name

      def group
        @group ||= alces.groups.send(genders.first)
      end

      private

      def genders
        @genders ||= NodeattrInterface.groups_for_node(name)
      end

      def hash_merger_input
        { groups: genders, node: name }
      end

      def additional_dynamic_namespace
        { node: self }
      end
    end
  end
end
