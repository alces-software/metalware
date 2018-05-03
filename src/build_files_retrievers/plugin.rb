# frozen_string_literal: true

module Metalware
  module BuildFilesRetrievers
    class Plugin < BuildFilesRetriever
      private

      def node
        namespace.node_namespace
      end
    end
  end
end
