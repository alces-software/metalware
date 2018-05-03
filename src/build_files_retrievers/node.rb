# frozen_string_literal: true

module Metalware
  module BuildFilesRetrievers
    class Node < BuildFilesRetriever
      private

      def node
        namespace
      end
    end
  end
end
