
# frozen_string_literal: true

module Metalware
  module CommandHelpers
    module NodeIdentifier
      private

      MISSING_GENDER_WARNING = 'Could not find nodes for gender: '
      MISSING_NODE_WARNING = 'Could not find node: '

      attr_reader :node_identifier

      def pre_setup(*a)
        super(*a)
        @node_identifier = args.first
      end

      def nodes
        raise_missing unless node_names
        @nodes ||= node_names.map { |n| alces.nodes.find_by_name(n) }
      end

      def node_names
        @node_names ||= if options.gender
                          NodeattrInterface.nodes_in_gender(node_identifier)
                        else
                          [node_identifier]
                        end
      end

      def raise_missing
        msg = warning + node_identifier
        raise InvalidInput, msg
      end

      def warning
        options.gender ? MISSING_GENDER_WARNING : MISSING_NODE_WARNING
      end
    end
  end
end
