
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
            Configurator.for_node(alces, node_name)
        end

        def answer_file
          file_path.node_answers(node_name)
        end
      end
    end
  end
end
