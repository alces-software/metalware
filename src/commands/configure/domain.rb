
# frozen_string_literal: true

require 'command_helpers/configure_command'
require 'constants'

module Metalware
  module Commands
    module Configure
      class Domain < CommandHelpers::ConfigureCommand
        private

        def setup; end

        def configurator
          @configurator ||=
            Configurator.for_domain(file_path: file_path)
        end
      end
    end
  end
end
