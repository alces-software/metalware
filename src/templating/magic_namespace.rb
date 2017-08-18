
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

require 'hashie'
require 'active_support/core_ext/hash'

require 'constants'
require 'deployment_server'
require 'nodeattr_interface'
require 'group_cache'
require 'templating/missing_parameter_wrapper'
require 'templating/group_namespace'
require 'object_fields_hasher'
require 'node'

module Metalware
  module Templating
    class MagicNamespace
      # `include_groups` = whether to include the group namespaces when
      # converting this `MagicNamespace` instance to a hash.
      def initialize(
        config:,
        node: nil,
        firstboot: nil,
        files: nil,
        include_groups: true
      )
        @metalware_config = config
        @node = Node.new(metalware_config, node)
        @firstboot = firstboot
        @files = Hashie::Mash.new(files) if files
        @include_groups = include_groups
      end

      attr_reader :firstboot, :files
      delegate :index, :group_index, to: :node
      delegate :to_json, to: :to_h

      def to_h
        ObjectFieldsHasher.hash_object(self, groups: :groups_data)
      end

      def nodename
        node.name
      end

      def answers
        # If we're templating for a particular node then we should be strict
        # about accessing answers which don't exist, as this indicates a
        # problem in the repo; otherwise (e.g. when rendering hosts or genders
        # templates) we should not be strict, to avoid erroring as many answers
        # may be unset.
        if node.name.present?
          MissingParameterWrapper.new(node.answers, raise_on_missing: true)
        else
          Hashie::Mash.new(node.answers)
        end
      end

      def genders
        # XXX Do we want to make genders available as a `Hashie::Mash` too?
        # Depends if we want to be able to iterate through genders or just get
        # list of nodes in a specified gender
        GenderGroupProxy
      end

      def groups
        group_cache.map do |group|
          yield group_namespace_for(group)
        end
      end

      def group_cache
        @group_cache ||= GroupCache.new(metalware_config)
      end

      def hunter
        if File.exist? Constants::HUNTER_PATH
          Hashie::Mash.load(Constants::HUNTER_PATH)
        else
          warning = \
            "#{Constants::HUNTER_PATH} does not exist; need to run " \
            "'metal hunter' first. Falling back to empty hash for alces.hunter."
          MetalLog.warn warning
          Hashie::Mash.new
        end
      end

      def hosts_url
        DeploymentServer.system_file_url 'hosts'
      end

      def genders_url
        DeploymentServer.system_file_url 'genders'
      end

      def kickstart_url
        DeploymentServer.kickstart_url(nodename)
      end

      def build_complete_url
        DeploymentServer.build_complete_url(nodename)
      end

      def hostip
        DeploymentServer.ip
      end

      private

      attr_reader :metalware_config, :node, :include_groups

      def group_namespace_for(group_name)
        GroupNamespace.new(metalware_config, group_name)
      end

      def groups_data
        return unless include_groups
        groups { |group| group }
      end

      module GenderGroupProxy
        class << self
          def method_missing(group_symbol)
            NodeattrInterface.nodes_in_group(group_symbol)
          rescue NoGenderGroupError => error
            warning = "#{error}. Falling back to empty array for alces.#{group_symbol}."
            MetalLog.warn warning
            []
          end
        end
      end
    end
  end
end
