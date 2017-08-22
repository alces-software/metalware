
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

require 'node'
require 'binding'
require 'templating/iterable_recursive_open_struct'

module Metalware
  module Templating
    class GroupNamespace
      attr_reader :name

      delegate :to_json, to: :to_h

      def initialize(metalware_config, group_name)
        @metalware_config = metalware_config
        @name = group_name
      end

      def answers
        IterableRecursiveOpenStruct.new(templating_configuration.answers)
      end

      def nodes
        NodeattrInterface.nodes_in_primary_group(name).map do |node_name|
          yield templating_config_for_node(node_name)
        end
      end

      def to_h
        ObjectFieldsHasher.hash_object(self, nodes: :nodes_data)
      end

      private

      attr_reader :metalware_config

      # XXX Confusingly the following two methods are both related to
      # 'templating configs' but mean slightly different things by this - this
      # one means the full config that would be available for this node when
      # templating for it, while the next refers to the class for accessing the
      # raw configuration files applicable to this group. This should be
      # improved.
      def templating_config_for_node(node_name)
        Binding.build_wrapper(metalware_config, node_name)
      end

      def templating_configuration
        @templating_configuration ||=
          Configuration.for_primary_group(name, config: metalware_config)
      end

      def nodes_data
        nodes { |node| node }
      end
    end
  end
end
