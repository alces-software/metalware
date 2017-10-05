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

        private

        def group_cache
          @group_cache ||= GroupCache.new(config)
        end
      end
    end
  end
end
