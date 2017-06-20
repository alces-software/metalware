
require 'base_command'
require 'configurator'
require 'constants'


module Metalware
  module Commands
    module Configure

      class Domain < BaseCommand
        def setup(_args, _options)
        end

        def run
          configurator.configure
        end

        def handle_interrupt(_e)
          abort 'Exiting without saving...'
        end

        private

        def configurator
          Configurator.new(
            highline: self,
            configure_file: config.configure_file,
            questions: :domain,
            answers_file: answers_file
          )
        end

        def answers_file
          File.join(Constants::ANSWERS_PATH, 'domain.yaml')
        end
      end

    end
  end
end
