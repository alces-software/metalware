
require 'command_helpers/base_command'
require 'configurator'
require 'constants'

module Metalware
  module CommandHelpers
    class ConfigureCommand < CommandHelpers::BaseCommand
      def run
        configurator.configure
      end

      def handle_interrupt(_e)
        abort 'Exiting without saving...'
      end

      protected

      def answers_file
        raise NotImplementedError
      end

      private

      def dependencies_hash
        {
          repo: true
        }
      end

      def configurator
        Configurator.new(
          configure_file: config.configure_file,
          questions_section: questions_section,
          answers_file: answers_file
        )
      end

      def questions_section
        self.class.name.split('::')[-1].downcase.to_sym
      end
    end
  end
end
