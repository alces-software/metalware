# frozen_string_literal: true

require 'input'

require 'build_files_retrievers/build_files_retriever'
require 'build_files_retrievers/plugin'
require 'build_files_retrievers/node'

module Metalware
  module BuildFilesRetrievers
    class Cache
      delegate :download, to: :input

      def retrieve(namespace)
        build_class = case namespace
                      when Namespaces::Node
                        BuildFilesRetrievers::Node
                      when Namespaces::Plugin
                        BuildFilesRetrievers::Plugin
                      else
                        raise InternalError, 'Can not find files'
                      end
        build_class.new(self, namespace).retrieve
      end

      def input
        @input ||= Input::Cache.new
      end
    end
  end
end
