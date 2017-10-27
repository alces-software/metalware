# frozen_string_literal: true

require 'active_support/core_ext/string/strip'
require 'nodeattr_interface'
require 'group_cache'
require 'hashie'

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

        def hunter
          @hunter ||= begin
            if File.exist? Constants::HUNTER_PATH
              Hashie::Mash.load(Constants::HUNTER_PATH)
            else
              warning = \
                "#{Constants::HUNTER_PATH} does not exist; need to run " \
                "'metal hunter' first. Falling back to empty hash for" \
                'alces.hunter.'
              MetalLog.warn warning
              Hashie::Mash.new
            end
          end
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
          @build_files_retriever ||= BuildFilesRetriever.new(metal_config)
        end

        private

        def group_cache
          @group_cache ||= GroupCache.new(metal_config)
        end
      end
    end
  end
end
