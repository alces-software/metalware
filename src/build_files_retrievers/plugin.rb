# frozen_string_literal: true

module Metalware
  module BuildFilesRetrievers
    class Plugin < BuildFilesRetriever
      private

      def node
        namespace.node_namespace
      end

      def rendered_sub_dir
        File.join('plugin', namespace.name)
      end

      def local_template_dir
        namespace.plugin.path
      end
    end
  end
end
