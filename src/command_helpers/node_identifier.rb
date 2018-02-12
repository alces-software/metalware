
# frozen_string_literal: true

module Metalware
  module CommandHelpers
    module NodeIdentifier
      private

      def pre_setup(*a)
        super(*a)
        @node_identifier = args.first
      end

      attr_reader :node_identifier

      def nodes
        @nodes ||= begin
          nodes = if options.group
                    NodeattrInterface.nodes_in_gender(node_identifier)
                                     .map do |node|
                                       alces.nodes.find_by_name node
                                     end
                  else
                    alces.nodes.find_by_name(node_identifier)
                  end
          raise_missing unless nodes
          Array(nodes)
        end
      end

      def group
        @group ||= begin
          return unless options.group
          alces.groups.find_by_name(node_identifier)
        end
      end

      MISSING_GROUP_WARNING = 'Could not find group: '
      MISSING_NODE_WARNING = 'Could not find node: '

      def raise_missing
        msg = if options.group
                MISSING_GROUP_WARNING.to_s + node_identifier
              else
                MISSING_NODE_WARNING.to_s + node_identifier
              end
        raise InvalidInput, msg
      end
    end
  end
end
