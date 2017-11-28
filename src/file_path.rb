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
require 'config'

module Metalware
  class FilePath
    class << self
      # TODO: Remove the new method. It only ensures backwards compatibility
      def new(*_args)
        self
      end

      def configure_file
        config.configure_file
      end

      def domain_answers
        config.domain_answers_file
      end

      def group_answers(group)
        config.group_answers_file(group)
      end

      def node_answers(node)
        config.node_answers_file(node)
      end

      def local_answers
        node_answers('local')
      end

      def domain_config
        File.join(repo, 'config/domain.yaml')
      end

      def group_config(group)
        File.join(repo, 'config', "#{group}.yaml")
      end

      def node_config(node)
        File.join(repo, 'config', "#{node}.yaml")
      end

      def local_config
        File.join(repo, 'config/local.yaml')
      end

      def server_config
        File.join(repo, 'server.yaml')
      end

      def repo
        config.repo_path
      end

      def repo_relative_path_to(path)
        repo_path = Pathname.new(repo)
        Pathname.new(path).relative_path_from(repo_path).to_s
      end

      def template_path(template_type, node:)
        File.join(
          config.repo_path,
          template_type.to_s,
          template_file_name(template_type, node: node)
        )
      end

      def template_save_path(template_type, node: nil)
        node = Node.new(config, nil) if node.nil?
        File.join(
          config.rendered_files_path,
          template_type.to_s,
          node.name
        )
      end

      def named_zone(zone)
        File.join(var_named, zone)
      end

      def build_complete(name)
        File.join(config.built_nodes_storage_path, "metalwarebooter.#{name}")
      end

      def rendered_build_file_path(node_name, namespace, file_name)
        File.join(
          config.rendered_files_path,
          node_name,
          namespace.to_s,
          file_name
        )
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

      private

      def config
        Config.cache
      end

      def template_file_name(template_type, node:)
        node.config.templates&.send(template_type) || 'default'
      end

      def answer_files
        config.answer_files_path
      end
    end
  end
end

Metalware::FilePath.define_constant_paths
