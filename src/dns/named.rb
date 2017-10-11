
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
      def initialize(alces)
        @alces = alces
        @config = alces.send(:metal_config)
      end

      def update
        render_repo_named_conf
        each_network do |zone, net|
          render_zone_template('forward', zone, net)
          render_zone_template('reverse', zone, net)
        end
        restart_named
      end

      private

      attr_reader :config, :alces

      def file_path
        @file_path ||= FilePath.new(config)
      end

      def render_base_named_conf
        Templater.render_to_file(alces, file_path.named_template, file_path.base_named)
      end

      def render_repo_named_conf
        FileUtils.mkdir_p(File.dirname(file_path.metalware_named))
        template_path = file_path.template_path('named', node: alces.domain)
        Templater.render_to_file(alces,
                                 template_path,
                                 file_path.metalware_named)
      end

      def restart_named
        MetalLog.info 'Restarting named'
        SystemCommand.run('systemctl restart named')
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
        Templater.render_to_file(
          alces,
          file_path.template_path("named/#{direction}", node: alces.domain),
          file_path.named_zone(zone_name),
          dynamic_namespace
        )
      end
    end
  end
end
