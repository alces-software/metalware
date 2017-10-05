# frozen_string_literal: true

module Metalware
  module Namespaces
    class Nodes < Array
      def initialize(alces)
        super()
        create_node_namespaces(alces)
        define_node_methods
        freeze
      end

      private

      def create_node_namespaces(alces)
        nodes = NodeattrInterface.all_nodes.map do |node_name|
          Namespaces::Node.new(alces, node_name)
        end
        push(*nodes)
      end

      def define_node_methods
        each { |node| define_singleton_method(node.name.to_sym) { node } }
      end
    end
  end
end
