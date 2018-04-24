# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Unlink < CommandHelpers::BaseCommand
        private

        attr_reader :node_name, :cache

        def setup
          @node_name = args[0]
          @cache = Cache::Asset.new
        end

        def run
          unassign_node_from_cache
        end

        def unassign_node_from_cache
          cache.unassign_node(node_name)
          cache.save
        end
      end
    end
  end
end
