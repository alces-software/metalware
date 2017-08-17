
# frozen_string_literal: true

require 'command_helpers/configure_command'
require 'constants'

module Metalware
  module Commands
    module Configure
      class Node < CommandHelpers::ConfigureCommand
        private

        attr_reader :node_name

        def setup
          @node_name = args.first
        end

        def configurator
          @configurator ||=
            Configurator.for_node(node, file_path: file_path)
        end

        def node
          Metalware::Node.new(config, node_name)
        end

        def dependency_hash
          dependency_specifications.for_node_in_configured_group(node_name)
        end
      end
    end
  end
end
