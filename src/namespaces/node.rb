
# frozen_string_literal: true

module Metalware
  module Namespaces
    class Node < HashMergerNamespace
      attr_reader :name

      def group
        @group ||= alces.groups.send(genders.first)
      end

      def index
        @index ||= begin
          group.nodes.each_with_index do |other_node, index|
            return(index + 1) if other_node == self
          end
          raise InternalError, 'Node does not appear in its primary group'
        end
      end

      def ==(other_node)
        other_node.name == name
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
