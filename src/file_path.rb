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
require 'file_path/config_path'

module Metalware
  module FilePath
    class << self
      delegate :domain_config,
               :group_config,
               :node_config,
               :local_config,
               to: :config_path

      def configure_file
        File.join(repo, 'configure.yaml')
      end

      def domain_answers
        File.join(answer_files, 'domain.yaml')
      end

      def group_answers(group)
        file_name = "#{group}.yaml"
        File.join(answer_files, 'groups', file_name)
      end

      def node_answers(node)
        file_name = "#{node}.yaml"
        File.join(answer_files, 'nodes', file_name)
      end

      def local_answers
        node_answers('local')
      end

      def answer_files
        File.join(metalware_data, 'answers')
      end

      def server_config
        File.join(repo, 'server.yaml')
      end

      def repo
        File.join(metalware_data, 'repo')
      end

      def overview
        File.join(repo, 'overview.yaml')
      end

      def plugins_dir
        File.join(metalware_data, 'plugins')
      end

      # TODO: Change input from node to namespace
      def template_path(template_type, node:)
        File.join(
          repo,
          template_type.to_s,
          template_file_name(template_type, node: node)
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

      def rendered_build_file_path(rendered_dir, section, file_name)
        File.join(
          rendered_files,
          rendered_dir,
          section.to_s,
          file_name
        )
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

      def asset_type(type)
        File.join(metalware_install, 'data/asset_types', type + '.yaml')
      end

      def asset(*a)
        record(asset_dir, *a)
      end

      def asset_dir
        File.join(metalware_data, 'assets')
      end

      def layout(*a)
        record(layout_dir, *a)
      end

      def layout_dir
        File.join(metalware_data, 'layouts')
      end

      def asset_cache
        File.join(cache, 'assets.yaml')
      end

      def cached_template(name)
        File.join(cache, 'templates', name)
      end

      def build_hooks
        File.join(metalware_data, 'build_hooks')
      end

      private

      def record(record_dir, types_dir, name)
        File.join(record_dir, types_dir, name + '.yaml')
      end

      def template_file_name(template_type, node:)
        node.config.templates&.send(template_type) || 'default'
      end

      def config_path
        @config_path ||= ConfigPath.new(base: repo)
      end
    end
  end
end

Metalware::FilePath.define_constant_paths
