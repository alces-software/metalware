
require 'command_helpers/configure_command'
require 'constants'


module Metalware
  module Commands
    module Configure

      class Domain < CommandHelpers::ConfigureCommand
        def setup(_args, _options)
        end

        protected

        def answers_file
          File.join(Constants::ANSWERS_PATH, 'domain.yaml')
        end
      end

    end
  end
end
