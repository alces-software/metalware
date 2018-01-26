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
require 'file_path/config_path'

module Metalware
  class FilePath
    class << self
      delegate :domain_config,
               :group_config,
               :node_config,
               :local_config,
               to: :config_path

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

      def server_config
        File.join(repo, 'server.yaml')
      end

      def repo
        config.repo_path
      end

      def plugins_dir
        File.join(Constants::METALWARE_DATA_PATH, 'plugins')
      end

      def repo_relative_path_to(path)
        repo_path = Pathname.new(repo)
        Pathname.new(path).relative_path_from(repo_path).to_s
      end

      # TODO: Change input from node to namespace
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

      def build_complete(node_namespace)
        event(node_namespace, 'complete')
      end

      def rendered_build_file_path(rendered_dir, section, file_name)
        File.join(
          config.rendered_files_path,
          rendered_dir,
          section.to_s,
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

      def new_config_if_missing(&block)
        @new_if_missing = true
        instance_exec(&block)
      ensure
        @new_if_missing = false
      end

      def event(node_namespace, event = '')
        File.join(events_dir, node_namespace.name, event)
      end

      private

      attr_reader :new_if_missing

      def config
        Config.cache(new_if_missing: new_if_missing)
      end

      def template_file_name(template_type, node:)
        node.config.templates&.send(template_type) || 'default'
      end

      def answer_files
        config.answer_files_path
      end

      def config_path
        @config_path ||= ConfigPath.new(base: repo)
      end
    end
  end
end

Metalware::FilePath.define_constant_paths
