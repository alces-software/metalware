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
require 'templating/repo_config_parser'

module Metalware
  class FilePath
    def initialize(metalware_config)
      @config = metalware_config
      define_constant_paths
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

    def self_answers
      File.join(answer_files, 'self.yaml')
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

    def self_config
      File.join(repo, 'config/self.yaml')
    end

    def repo
      config.repo_path
    end

    def repo_relative_path_to(path)
      repo_path = Pathname.new(repo)
      Pathname.new(path).relative_path_from(repo_path).to_s
    end

    def template_path(template_type, node: nil)
      node = Node.new(config, nil) if node.nil?
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

    private

    attr_reader :config

    def define_constant_paths
      Constants.constants
               .map(& :to_s)
               .select { |const| /\A.+_PATH\Z/.match?(const) }
               .each do |const|
                 define_singleton_method :"#{const.chomp('_PATH').downcase}" do
                   Constants.const_get(const)
                 end
               end
    end

    def template_file_name(template_type, node:)
      repo_template(template_type, node: node) || 'default'
    end

    def repo_template(template_type, node:)
      # TODO: Remove conditional logic once fully switched to new namespace
      if node.respond_to?(:repo_config)
        (node.repo_config[:templates] || {})[template_type]
      else
        node.config.templates&.template_type
      end
    end

    def answer_files
      config.answer_files_path
    end
  end
end
