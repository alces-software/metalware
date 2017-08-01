
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

      def relative_answer_file
        answers_file.sub("#{config.answer_files_path}/", '')
      end

      def answers_file
        raise NotImplementedError
      end

      def higher_level_answer_files
        []
      end

      private

      GENDERS_INVALID_MESSAGE = <<-EOF.strip_heredoc
        You should be able to fix this error by re-running the `configure`
        command and correcting the invalid input, or by manually editing the
        appropriate answers file or template and using the `configure rerender`
        command to re-render the templates.
      EOF

      def dependency_hash
        {
          repo: ['configure.yaml'],
          optional: {
            configure: [relative_answer_file],
          },
        }
      end

      def configurator
        Configurator.new(
          configure_file: config.configure_file,
          questions_section: questions_section,
          answers_file: answers_file,
          higher_level_answer_files: higher_level_answer_files
        )
      end

      def questions_section
        class_name_parts.last
      end

      # Render the templates which are relevant across the whole domain; these
      # are re-rendered at the end of every configure command as the data used
      # in the templates could change with each command.
      def render_domain_templates
        DomainTemplatesRenderer.new(
          config,
          genders_invalid_message: GENDERS_INVALID_MESSAGE
        ).render
      end
    end
  end
end
