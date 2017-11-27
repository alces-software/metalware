
# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

require 'exceptions'
require 'constants'
require 'network'
require 'metal_log'
require 'active_support/core_ext/string/strip'
require 'dns/named'
require 'namespaces/alces'

#
# XXX: This is getting very long. It should be broken up into different
#      classes next time something needs to be added. Some of the render
#      mangaged files/ section can be moved into the `Templater` class.
#      The `Templater` class is a good location to keep all the file
#      handling methods so they can be reused.
#
#      Also the different render methods can be broken out in a smilar
#      way the `BuildMethods` are. This way the render method specific
#      code (e.g. the validation blocks) can exist in a seperate class.
#
module Metalware
  class DomainTemplatesRenderer
    def initialize(config, alces = nil, genders_invalid_message: nil)
      @config = config
      @alces = alces
      @genders_invalid_message = genders_invalid_message
    end

    def render
      render_methods.each do |method|
        rendered_file_invalid = !send(method)
        if rendered_file_invalid
          msg = "An error occurred rendering: #{method.to_s.sub('render_', '')}"
          raise DomainTemplatesInternalError, msg
        end
      end
    end

    private

    attr_reader :config, :genders_invalid_message

    def alces
      @alces ||= Metalware::Namespaces::Alces.new(config)
    end

    def render_methods
      # These are order dependent, as data used in later methods may depend on
      # earlier files having been rendered successfully.
      [
        :render_genders,
        :render_dns,
      ]
    end

    def display_server_config_error(build_interface:)
      interfaces_list = Network.interfaces.join(', ')
      Output.stderr \
        "\nAborting rendering domain templates; the rendered server config is invalid:"
      Output.stderr_indented_error_message \
        "#{build_interface} is not a valid interface; valid interfaces: #{interfaces_list}"
    end

    def render_genders
      render_managed_section_template(
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
      Output.stderr "\nAborting rendering domain templates; " \
        'the rendered genders file is invalid:'
      Output.stderr_indented_error_message(nodeattr_error)
      Output.stderr \
        "The rendered file can be found at #{Constants::INVALID_RENDERED_GENDERS_PATH}"
      Output.stderr "\n" + genders_invalid_message if genders_invalid_message
    end

    MISSING_DNS_TYPE = <<~EOF.strip_heredoc
      The DNS type has not been set. Reverting to default DNS type: 'hosts'. To
      prevent this message, please set "dns_type" in your repo configs, "domain.yaml"
      file.
    EOF

    def render_dns
      case alces.domain.config.dns_type
      when nil
        MetalLog.warn(MISSING_DNS_TYPE)
        render_hosts
      when 'hosts'
        render_hosts
      when 'named'
        update_named
      else
        msg = "Invalid DNS type: #{alces.domain.config.dns_type}"
        raise InvalidConfigParameter, msg
      end
    end

    def render_hosts
      render_managed_section_template(hosts_template, to: Constants::HOSTS_PATH)
    end

    def render_managed_section_template(template, to:, &block)
      Templater.render_managed_file(alces, template, to, &block)
    end

    def update_named
      DNS::Named.new(alces).update
    end

    def server_config_template
      File.join(config.repo_path, 'server.yaml')
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
