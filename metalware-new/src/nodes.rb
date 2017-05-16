
require 'active_support/core_ext/module/delegation'

require 'nodeattr_interface'
require 'node'


module Metalware
  class Nodes
    include Enumerable

    delegate :length, to: :@nodes

    def initialize(config, node_identifier, is_group)
      if is_group
        @nodes =
          NodeattrInterface.nodes_in_group(node_identifier)
          .map {|name| Node.new(config, name)}
      else
        @nodes = [Node.new(config, node_identifier)]
      end
    end

    def each(&block)
      @nodes.each(&block)
    end

    def template_each(**additional_template_parameters, &block)
      @nodes.each_with_index do |node, index|
        template_parameters = {
          nodename: node.name,
          index: index,
        }.merge(additional_template_parameters)
        templater = Templater::Combiner.new(template_parameters)

        block.call(templater, node)
      end
    end
  end
end
