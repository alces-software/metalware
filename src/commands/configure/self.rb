
# frozen_string_literal: true

require 'command_helpers/configure_command'
require 'constants'

module Metalware
  module Commands
    module Configure
      class Self < CommandHelpers::ConfigureCommand
        private

        def setup; end

        def answers_file
          file_path.self_answers
        end

        def self_node
          @self_node ||= Metalware::Node.new(config, 'self')
        end

        def configurator
          @configurator ||=
            Configurator.for_node(self_node, config: config)
        end
      end
    end
  end
end
