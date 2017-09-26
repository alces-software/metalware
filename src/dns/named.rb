
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
require 'templating/repo_config_parser'
require 'templater'
require 'exceptions'
require 'metal_log'

module Metalware
  module DNS
    class Named
      def initialize(metalware_config)
        @config = metalware_config
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

      attr_reader :config

      def file_path
        @file_path ||= FilePath.new(config)
      end

      def repo_config
        @repo_config ||= Templating::RepoConfigParser
                         .parse_for_domain(config: config,
                                           include_groups: false)
                         .inspect
      end

      def render_base_named_conf
        Templater.render_to_file(config, file_path.named_template, file_path.base_named)
      end

      def render_repo_named_conf
        FileUtils.mkdir_p(File.dirname(file_path.metalware_named))
        Templater.render_to_file(config,
                                 file_path.template_path('named'),
                                 file_path.metalware_named)
      end

      def restart_named
        MetalLog.info 'Restarting named'
        SystemCommand.run('systemctl restart named')
      end

      def each_network
        repo_config[:networks]&.each { |data| yield data }
      end

      def named_zone_hash(zone, net)
        {
          alces: {
            named: {
              zone: zone,
              net: net,
            },
          },
        }
      end

      def render_zone_template(direction, zone, net)
        zone_name = case direction
                    when 'forward'
                      net[:named_fwd_zone]
                    when 'reverse'
                      net[:named_rev_zone]
                    end
        zone_hash = named_zone_hash(zone, net)
        return unless zone_name
        Templater.render_to_file(config,
                                 file_path.template_path("named/#{direction}"),
                                 file_path.named_zone(zone_name),
                                 zone_hash)
      end
    end
  end
end
