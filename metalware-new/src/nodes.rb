
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
        templater = Templater.new(template_parameters)

        block.call(templater, node)
      end
    end

    private

    def initialize(nodes)
      @nodes = nodes
    end
  end
end
