
# frozen_string_literal: true

require 'command_helpers/configure_command'
require 'constants'

module Metalware
  module Commands
    module Configure
      class Domain < CommandHelpers::ConfigureCommand
        private

        def setup; end

        def answer_file
          file_path.domain_answers
        end

        def configurator
          @configurator ||=
            Configurator.for_domain(config: config)
        end
      end
    end
  end
end
