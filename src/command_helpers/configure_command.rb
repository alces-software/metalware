
# frozen_string_literal: true

require 'command_helpers/base_command'
require 'configurator'
require 'constants'

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
        # `hosts` file is typically rendered using info from `genders`, so if
        # the rendered `genders` is invalid we should not render it.
        render_hosts if render_genders
      end

      def render_genders
        render_template(
          genders_template,
          to: Constants::GENDERS_PATH
        ) do |rendered_genders|
          validate_rendered_genders(rendered_genders)
        end
      end

      def validate_rendered_genders(rendered_genders)
        genders_valid, nodeattr_error = Tempfile.open do |tempfile|
          tempfile.write(rendered_genders)
          tempfile.flush
          NodeattrInterface.validate_genders_file(tempfile.path)
        end

        unless genders_valid
          cache_invalid_genders(rendered_genders)
          display_genders_error(nodeattr_error)
        end

        genders_valid
      end

      def cache_invalid_genders(rendered_genders)
        File.write(Constants::INVALID_RENDERED_GENDERS_PATH, rendered_genders)
      end

      def display_genders_error(nodeattr_error)
        # XXX add note here about how to re-render templates once this is
        # directly supported.
        Output.stderr "\nAborting rendering domain templates; " \
          'the rendered genders file is invalid:'
        Output.stderr_indented_error_message(nodeattr_error)
        Output.stderr \
          "The rendered file can be found at #{Constants::INVALID_RENDERED_GENDERS_PATH}"
      end

      def render_hosts
        render_template(hosts_template, to: Constants::HOSTS_PATH)
      end

      def render_template(template, to:, &block)
        Templater.render_to_file(config, template, to, &block)
      end

      def genders_template
        template_path('genders')
      end

      def hosts_template
        template_path('hosts')
      end

      def template_path(template_type)
        # We currently always/only render the 'default' templates.
        File.join(config.repo_path, template_type, 'default')
      end
    end
  end
end
