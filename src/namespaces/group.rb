
# frozen_string_literal: true

module Metalware
  module Namespaces
    class Group < HashMergerNamespace
      include Mixins::Name

      def initialize(alces, name, index:)
        @index = index
        super(alces, name)
      end

      attr_reader :index

      def nodes
        @nodes ||= begin
          arr = NodeattrInterface.nodes_in_gender(name).map do |node_name|
            alces.nodes.send(node_name)
          end
          MetalArray.new(arr)
        end
      end

      def hostlist_nodes
        @short_nodes_string ||= begin
          NodeattrInterface.hostlist_nodes_in_gender(name)
        end
      end

      private

      def white_list_for_hasher
        super.concat([:index, :nodes, :hostlist_nodes])
      end

      def hash_merger_input
        { groups: [name] }
      end

      def additional_dynamic_namespace
        { group: self }
      end
    end
  end
end
