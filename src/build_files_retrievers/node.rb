# frozen_string_literal: true

module Metalware
  module BuildFilesRetrievers
    class Node < BuildFilesRetriever
      private

      def node
        namespace
      end

      def rendered_sub_dir
        'repo'
      end

      def local_template_dir
        FilePath.repo
      end
    end
  end
end
