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

require 'open3'

require 'constants'
require 'system_command'
require 'nodeattr_interface'
require 'exceptions'
require 'group_cache'
require 'templating/configuration'
require 'build_methods'
require 'binding'

module Metalware
  class Node
    attr_reader :name
    delegate :raw_config,
             :answers,
             # XXX `Node#configs` does not actually need to be public, it is only used
             # in the `Node` tests
             :configs,
             to: :templating_configuration

    delegate :render_build_started_templates,
             :render_build_complete_templates,
             to: :build_method

    def initialize(metalware_config, name, should_be_configured: false)
      @metalware_config = metalware_config
      @name = name

      # Node configured <=> is part of a group which has been configured; this
      # means we should be stricter when checking the node is in the genders
      # file etc.
      @should_be_configured = should_be_configured
    end

    # Two nodes are equal <=> their names are equal; everything else is derived
    # from this. This does mean they will appear equal if they are initialized
    # with different config files, but this is a bug if it occurs in practise.
    def ==(other_node)
      if other_node.is_a? Node
        name == other_node.name
      else
        false
      end
    end

    def hexadecimal_ip
      SystemCommand.run "gethostip -x #{name}"
    end

    def built?
      File.file? build_complete_marker_file
    end

    def groups
      NodeattrInterface.groups_for_node(name)
    rescue NodeNotInGendersError
      # Re-raise if we're expecting the node to be configured, as it should be
      # in the genders file.
      raise if should_be_configured

      # The node doesn't need to be in the genders file if it's not expected to
      # be configured, it's just part of no groups yet (XXX not sure if this is
      # still true, maybe we should be stricter now and always require a node
      # to be in the genders file).
      []
    end

    # Get the configured `files` for this node, to be rendered and used in
    # `build`. This is the merged namespaces with arrays of file identifiers
    # from all `files` namespaces within all configs for the node, with
    # identifiers in higher precedence configs replacing those with the same
    # basename in lower precendence configs.
    # XXX this may be better living in `Templating::Configuration`? `configs`
    # and `load_config` could then be private.
    def build_files
      files_memo = Hash.new { |k, v| k[v] = [] }
      configs.each_with_object(files_memo) do |config_name, files|
        config = templating_configuration.load_config(config_name)
        new_files = config[:files]
        merge_in_files!(files, new_files)
      end
    end

    # The path the file with given `file_name` within the given `namespace`
    # will be rendered to for this node.
    def rendered_build_file_path(namespace, file_name)
      File.join(
        metalware_config.rendered_files_path,
        name,
        namespace.to_s,
        file_name
      )
    end

    def index
      if primary_group
        Nodes.create(metalware_config, primary_group, true).index(self) + 1
      else
        0
      end
    end

    def group_index
      primary_group_index || 0
    end

    def primary_group
      groups.first
    end

    def build_template_paths
      build_method.template_paths
    end

    def query_repo(value)
      parameter_binding.eval(value.to_s)
    end

    private

    attr_reader :metalware_config, :should_be_configured

    def templating_configuration
      @templating_configuration ||=
        Templating::Configuration.for_node(name, config: metalware_config)
    end

    def build_complete_marker_file
      File.join(metalware_config.built_nodes_storage_path, "metalwarebooter.#{name}")
    end

    def primary_group_index
      group_cache.index(primary_group)
    end

    def group_cache
      GroupCache.new(metalware_config)
    end

    def merge_in_files!(existing_files, new_files)
      new_files&.each do |namespace, file_identifiers|
        file_identifiers.each do |file_identifier|
          replace_file_with_same_basename!(existing_files[namespace], file_identifier)
        end
      end
    end

    def replace_file_with_same_basename!(files_namespace, file_identifier)
      files_namespace.reject! { |f| same_basename?(file_identifier, f) }
      files_namespace << file_identifier
      files_namespace.sort! # Sort for consistent ordering.
    end

    def same_basename?(path1, path2)
      File.basename(path1) == File.basename(path2)
    end

    def build_method
      @build_method ||= build_method_class.new(metalware_config, self)
    end

    def parameter_binding
      @parameter_binding ||= begin
        Metalware::Binding.build(metalware_config, name)
      end
    end

    def build_method_class
      case query_repo(:build_method)&.to_sym
      when :basic
        BuildMethods::Basic
      else
        BuildMethods::Kickstart
      end
    end
  end
end
