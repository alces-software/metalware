
# frozen_string_literal: true

module Metalware
  module Namespaces
    class Group < HashMergerNamespace
      def initialize(alces, name, index:)
        @index = index
        super(alces, name)
      end

      attr_reader :name, :index

      def nodes
        @nodes ||= begin
          arr = NodeattrInterface.nodes_in_group(name).map do |node_name|
            alces.nodes.send(node_name)
          end
          MetalArray.new(arr)
        end
      end

      def ==(other_group)
        other_group.name == name
      end

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
