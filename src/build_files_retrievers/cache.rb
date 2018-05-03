# frozen_string_literal: true

require 'build_files_retriever'
require 'input'

module Metalware
  module BuildFilesRetrievers
    class Cache
      def retrieve(namespace)
        BuildFilesRetriever.new(input, namespace)
                           .retrieve
      end

      def input
        @input ||= Input::Cache.new
      end
    end
  end
end
