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

require 'constants'

module Metalware
  module FilePath
    class << self
      def repo
        File.join(metalware_data, 'repo')
      end

      def repo_template_path(template_type, namespace:)
        File.join(
          repo,
          template_type.to_s,
          template_file_name(template_type, namespace: namespace)
        )
      end

      def template_save_path(template_type, node: nil)
        node = Node.new(config, nil) if node.nil?
        File.join(
          rendered_files,
          template_type.to_s,
          node.name
        )
      end

      def named_zone(zone)
        File.join(var_named, zone)
      end

      def build_complete(node_namespace)
        event(node_namespace, 'complete')
      end

      def rendered_files
        rendered_dir
      end

      def staging(path)
        File.join(staging_dir, path)
      end

      def define_constant_paths
        Constants.constants
                 .map(& :to_s)
                 .select { |const| /\A.+_PATH\Z/.match?(const) }
                 .each do |const|
                   method_name = :"#{const.chomp('_PATH').downcase}"
                   define_singleton_method method_name do
                     Constants.const_get(const)
                   end
                 end
      end

      def event(node_namespace, event = '')
        File.join(events_dir, node_namespace.name, event)
      end

      def pxelinux_cfg
        '/var/lib/tftpboot/pxelinux.cfg'
      end

      def log
        '/var/log/metalware'
      end

      def build_hooks
        File.join(metalware_data, 'build_hooks')
      end

      private

      def record(record_dir, types_dir, name)
        File.join(record_dir, types_dir, name + '.yaml')
      end

      def template_file_name(template_type, namespace:)
        namespace.config.templates&.send(template_type) || 'default'
      end
    end
  end
end

Metalware::FilePath.define_constant_paths
