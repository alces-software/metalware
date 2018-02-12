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

require 'command_helpers/base_command'
require 'command_helpers/node_identifier'
require 'templater'
require 'dns'
require 'render_methods'

module Metalware
  module Commands
    class Template < CommandHelpers::BaseCommand
      private

      prepend CommandHelpers::NodeIdentifier

      attr_reader :build_methods

      def setup
        @build_methods = nodes.map(&:build_method)
      end

      def run
        Staging.template do |templater|
          build_methods.each do |build_method|
            build_method.render_staging_templates(templater)
          end
          dns_class.new(alces, templater).update
          RenderMethods::DHCP.render_to_staging(alces.domain, templater)
        end
      end

      MISSING_DNS_TYPE = <<~EOF.strip_heredoc
        The DNS type has not been set. Reverting to default DNS type: 'hosts'. To
        prevent this message, please set "dns_type" in your repo configs, "domain.yaml"
        file.
     EOF

      def dns_class
        case alces.domain.config.dns_type
        when nil
          MetalLog.warn(MISSING_DNS_TYPE)
          DNS::Hosts
        when 'hosts'
          DNS::Hosts
        when 'named'
          DNS::Named
        else
          msg = "Invalid DNS type: #{alces.domain.config.dns_type}"
          raise InvalidConfigParameter, msg
        end
      end
    end
  end
end
