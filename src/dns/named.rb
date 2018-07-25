
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

require 'validation/loader'
require 'pathname'
require 'system_command'
require 'templater'
require 'exceptions'
require 'metal_log'

module Metalware
  module DNS
    class Named
      def self.restart_service
        MetalLog.info 'Restarting named'
        SystemCommand.run('systemctl restart named')
      end

      def initialize(alces, templater)
        @alces = alces
        @templater = templater
      end

      def update
        render_repo_named_conf
        each_network do |zone, net|
          render_zone_template('forward', zone, net)
          render_zone_template('reverse', zone, net)
        end
      end

      private

      attr_reader :alces, :templater

      def render_repo_named_conf
        template_path = FilePath.template_path('named', node: alces.domain)
        templater.render(alces,
                         template_path,
                         FilePath.metalware_named,
                         **staging_options)
      end

      def each_network
        alces.domain.config.networks&.each { |*data| yield(*data) }
      end

      def build_dynamic_namespace(zone, net)
        {
          named: {
            zone: zone,
            net: net,
          },
        }
      end

      def render_zone_template(direction, zone, net)
        zone_name = case direction
                    when 'forward'
                      net.named_fwd_zone
                    when 'reverse'
                      net.named_rev_zone
                    end
        return unless zone_name
        dynamic_namespace = build_dynamic_namespace(zone, net)
        templater.render(
          alces,
          FilePath.template_path("named/#{direction}", node: alces.domain),
          FilePath.named_zone(zone_name),
          dynamic: dynamic_namespace,
          comment_char: ';',
          **staging_options
        )
      end

      def staging_options
        {
          mkdir: true,
          service: self.class.name,
          managed: true,
        }
      end
    end
  end
end
