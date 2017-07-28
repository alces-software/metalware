
# frozen_string_literal: true

require 'command_helpers/configure_command'
require 'constants'

module Metalware
  module Commands
    module Configure
      class Node < CommandHelpers::ConfigureCommand
        def setup(args, _options)
          @node_name = args.first
        end

        protected

        def answers_file
          config.node_answers_file(node_name)
        end

        private

        attr_reader :node_name

        def dependency_hash
          dependency_specifications.for_node_in_configured_group(node_name)
        end
      end
    end
  end
end
