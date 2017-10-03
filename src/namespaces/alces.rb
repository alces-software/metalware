
# frozen_string_literal: true

require 'exceptions'
require 'templating/renderer'
require 'nodeattr_interface'
require 'namespaces/node'
require 'config'

module Metalware
  module Namespaces
    class Alces
      def initialize(config)
        @config = config
        @dynamic_stack = []
      end

      def alces
        self
      end

      def render_erb_template(template_string, dynamic_namespace = {})
        run_with_dynamic(dynamic_namespace) do
          Templating::Renderer.replace_erb_with_binding(template_string, binding)
        end
      end

      def nodes
        @nodes ||= begin
          NodeattrInterface.all_nodes
                           .map do |node_name|
                             Namespaces::Node.new(config, self, node_name)
                           end
        end
      end

      ##
      # method_missing is used to access the dynamic namespace
      #
      def method_missing(s, *_a, &_b)
        respond_to_missing?(s) ? current_dynamic_namespace[s] :  super
      end

      def respond_to_missing?(s)
        current_dynamic_namespace.key?(s)
      end

      private

      attr_reader :config, :recursion_count, :dynamic_stack

      def run_with_dynamic(namespace)
        if dynamic_stack.length > Constants::MAXIMUM_RECURSIVE_CONFIG_DEPTH
          raise RecursiveConfigDepthExceededError
        end
        dynamic_stack.push(namespace)
        result = yield
        dynamic_stack.pop
        result
      end

      def current_dynamic_namespace
        dynamic_stack.last 
      end
    end
  end
end
