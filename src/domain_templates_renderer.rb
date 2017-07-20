
# frozen_string_literal: true

require 'constants'
require 'io'

module Metalware
  class DomainTemplatesRenderer
    def initialize(config)
      @config = config
    end

    def render
      # `hosts` file is typically rendered using info from `genders`, so if
      # the rendered `genders` is invalid we should not render it.
      if render_genders
        render_hosts
      else
        Io.abort
      end
    end

    private

    attr_reader :config

    def render_genders
      render_template(
        genders_template,
        to: Constants::GENDERS_PATH
      ) do |rendered_genders|
        validate_rendered_genders(rendered_genders)
      end
    end

    def validate_rendered_genders(rendered_genders)
      genders_valid, nodeattr_error = validate_genders_using_nodeattr(rendered_genders)
      handle_invalid_genders(rendered_genders, nodeattr_error) unless genders_valid
      genders_valid
    end

    def validate_genders_using_nodeattr(rendered_genders)
      Tempfile.open do |tempfile|
        tempfile.write(rendered_genders)
        tempfile.flush
        NodeattrInterface.validate_genders_file(tempfile.path)
      end
    end

    def handle_invalid_genders(rendered_genders, nodeattr_error)
      cache_invalid_genders(rendered_genders)
      display_genders_error(nodeattr_error)
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
