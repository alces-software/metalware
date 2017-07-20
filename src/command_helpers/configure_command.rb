
# frozen_string_literal: true

require 'command_helpers/base_command'
require 'configurator'
require 'domain_templates_renderer'

module Metalware
  module CommandHelpers
    class ConfigureCommand < BaseCommand
      def run
        configurator.configure
        custom_configuration
        render_domain_templates
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

      def dependency_hash
        {
          repo: ['configure.yaml'],
          configure: [],
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
        class_name_parts.last
      end

      # Render the templates which are relevant across the whole domain; these
      # are re-rendered at the end of every configure command as the data used
      # in the templates could change with each command.
      def render_domain_templates
        DomainTemplatesRenderer.new(config).render
      end
    end
  end
end
