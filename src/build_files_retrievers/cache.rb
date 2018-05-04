# frozen_string_literal: true

require 'input'
require 'digest'

require 'build_files_retrievers/build_files_retriever'
require 'build_files_retrievers/plugin'
require 'build_files_retrievers/node'

module Metalware
  module BuildFilesRetrievers
    class Cache
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

      def download(url)
        sha_identifier = Digest::SHA1.hexdigest(url)
        return return_result(sha_identifier) if cached[sha_identifier]
        begin
          FilePath.cached_template(sha_identifier).tap do |path|
            Input.download(url, path)
          end
        rescue StandardError => e
          e
        end.tap { |result| cached[sha_identifier] = result }
        return_result(sha_identifier)
      end

      private

      def cached
        @cached ||= {}
      end

      def return_result(sha_identifier)
        cached[sha_identifier].tap { |r| raise r if r.is_a?(Exception) }
      end
    end
  end
end
