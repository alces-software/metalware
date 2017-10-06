# frozen_string_literal: true

require 'nodeattr_interface'
require 'group_cache'

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
              Namespaces::Node.new(alces, node_name)
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

        private

        def group_cache
          @group_cache ||= GroupCache.new(config)
        end
      end
    end
  end
end
