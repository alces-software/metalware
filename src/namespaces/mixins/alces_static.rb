# frozen_string_literal: true

require 'active_support/core_ext/string/strip'
require 'nodeattr_interface'
require 'group_cache'
require 'hashie'
require 'validation/loader'
require 'cache/asset'
require 'build_files_retrievers/cache'

module Metalware
  module Namespaces
    module Mixins
      module AlcesStatic
        def alces
          self
        end

        def domain
          @domain ||= Namespaces::Domain.new(alces)
        end

        def nodes
          @nodes ||= begin
            arr = NodeattrInterface.all_nodes.map do |node_name|
              Namespaces::Node.create(alces, node_name)
            end
            Namespaces::MetalArray.new(arr)
          end
        end

        def groups
          @groups ||= begin
            arr = group_cache.map do |group_name|
              index = group_cache.index(group_name)
              Namespaces::Group.new(alces, group_name, index: index)
            end
            Namespaces::MetalArray.new(arr)
          end
        end

        def data
          DataFileNamespace.new
        end

        LOCAL_ERROR = <<-EOF.strip_heredoc
          The local node has not been configured
          Please run: `metal configure local`
        EOF

        def local
          @local ||= begin
            unless nodes.respond_to?(:local)
              raise UninitializedLocalNode, LOCAL_ERROR
            end
            nodes.local
          end
        end

        def build_files_retriever
          @build_files_retriever ||= BuildFilesRetrievers::Cache.new
        end

        def orphan_list
          @orphan_list ||= group_cache.orphans
        end

        def questions
          @questions ||= loader.question_tree
        end

        def assets
          @assets ||= AssetArray.new(self)
        end

        def asset_cache
          @asset_cache ||= Metalware::Cache::Asset.new
        end

        private

        def group_cache
          @group_cache ||= GroupCache.new
        end

        def loader
          @loader ||= Validation::Loader.new
        end

        class DataFileNamespace
          delegate :namespace_data_file, to: FilePath

          def method_missing(message, *_args)
            data_file_path = namespace_data_file(message)
            if respond_to?(message)
              Hashie::Mash.load(data_file_path)
            else
              # Normally `method_missing` should call `super` if it doesn't
              # `respond_to?` a message. In this case this is a namespace
              # designed to be used by users writing templates, so give them an
              # informative error message for what they've probably missed
              # instead. This does mean though that we could get a confusing
              # error message if something else goes wrong in this class, so I
              # could eventually come to regret this.
              raise UserMetalwareError,
                    "Requested data file doesn't exist: #{data_file_path}"
            end
          end

          def respond_to_missing?(message, _include_all = false)
            data_file_path = namespace_data_file(message)
            File.exist?(data_file_path)
          end
        end
      end
    end
  end
end
