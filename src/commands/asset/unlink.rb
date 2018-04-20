# frozen_string_literal: true

module Metalware
  module Commands
    module Asset
      class Unlink < Metalware::CommandHelpers::BaseCommand
        include CommandHelpers::AssetHelper

        private

        attr_reader :node_name

        def setup
          @node_name = args[0]
        end

        def run
          unassign_node_from_cache(node_name)
        end
      end
    end
  end
end
