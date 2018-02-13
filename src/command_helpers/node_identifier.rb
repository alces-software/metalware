
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
          nodes = if options.gender
                    NodeattrInterface.nodes_in_gender(node_identifier)
                  else
                    node_identifier
                  end
          raise_missing unless nodes
          Array.wrap(nodes).map { |n| alces.nodes.find_by_name(n) }
        end
      end

      MISSING_GENDER_WARNING = 'Could not find nodes for gender: '
      MISSING_NODE_WARNING = 'Could not find node: '

      def raise_missing
        msg = if options.gender
                MISSING_GENDER_WARNING.to_s + node_identifier
              else
                MISSING_NODE_WARNING.to_s + node_identifier
              end
        raise InvalidInput, msg
      end
    end
  end
end
