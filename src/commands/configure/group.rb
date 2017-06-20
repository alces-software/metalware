
require 'base_command'
require 'configurator'
require 'constants'


module Metalware
  module Commands
    module Configure

      class Group < BaseCommand
        def setup(args, _options)
          @group_name = args.first
        end

        def run
          configurator.configure
        end

        def handle_interrupt(_e)
          abort 'Exiting without saving...'
        end

        private

        attr_reader :group_name

        def configurator
          Configurator.new(
            highline: self,
            configure_file: config.configure_file,
            questions: :group,
            answers_file: answers_file
          )
        end

        def answers_file
          File.join(Constants::ANSWERS_PATH, 'groups', group_name)
        end
      end

    end
  end
end
