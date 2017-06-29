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

require 'active_support/core_ext/module/delegation'

require 'nodeattr_interface'
require 'node'


module Metalware
  class Nodes
    include Enumerable

    # Private as can only get `Nodes` instance via other methods in this class.
    private_class_method :new

    delegate :length, :each, to: :@nodes

    # Create instance of `Nodes` from a single node or gender group.
    def self.create(config, node_identifier, is_group)
      if is_group
        nodes = NodeattrInterface.nodes_in_group(node_identifier)
          .map {|name| Node.new(config, name)}
      else
        nodes = [Node.new(config, node_identifier)]
      end

      new(nodes)
    end

    def select(&block)
      nodes = @nodes.select(&block)

      # Return result as `Nodes` instance rather than array of `Node`s.
      self.class.send(:new, nodes)
    end

    def template_each(**additional_template_parameters, &block)
      @nodes.each_with_index do |node, index|
        template_parameters = {
          nodename: node.name,
          index: index,
        }.merge(additional_template_parameters)

        block.call(template_parameters, node)
      end
    end

    private

    def initialize(nodes)
      @nodes = nodes
    end
  end
end
