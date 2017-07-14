
require 'command_helpers/base_command'
require 'configurator'
require 'constants'

module Metalware
  module CommandHelpers
    class ConfigureCommand < BaseCommand
      def run
        configurator.configure
        custom_configuration
      end

      def handle_interrupt(_e)
        abort 'Exiting without saving...'
      end

      protected

      def custom_configuration
        # Custom additional configuration for a `configure` command, if any,
        # should be performed in this method in subclasses.
      end

      def answers_file
        raise NotImplementedError
      end

      private

      def dependencies_hash
        {
          repo: ["configure.yaml"],
          configure: []
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
