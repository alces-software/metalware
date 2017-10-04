# frozen_string_literal: true

module Metalware
  module Namespaces
    class Nodes
      include Enumerable

      delegate :each, :inspect, to: :nodes

      private

      def nodes
        @nodes ||= NodeattrInterface
                     .all_nodes
                     .map do |node_name|
          Namespaces::Node.new(self, node_name)
        end
      end
    end
  end
end
