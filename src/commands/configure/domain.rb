
# frozen_string_literal: true

require 'command_helpers/configure_command'
require 'constants'

module Metalware
  module Commands
    module Configure
      class Domain < CommandHelpers::ConfigureCommand
        private

        def setup; end

        def answers_file
          config.domain_answers_file
        end
      end
    end
  end
end
