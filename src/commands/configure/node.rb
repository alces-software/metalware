
# frozen_string_literal: true

require 'command_helpers/configure_command'
require 'constants'

module Metalware
  module Commands
    module Configure
      class Node < CommandHelpers::ConfigureCommand
        private

        attr_reader :node_name

        def setup(args, _options)
          @node_name = args.first
        end

        def answers_file
          config.node_answers_file(node_name)
        end

        def higher_level_answer_files
          [
            config.domain_answers_file,
            config.group_answers_file(node.primary_group),
          ]
        end

        attr_reader :node_name

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
