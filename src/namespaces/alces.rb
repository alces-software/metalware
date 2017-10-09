
# frozen_string_literal: true

require 'exceptions'
require 'templating/renderer'
require 'config'
require 'utils/dynamic_require'
require 'deployment_server'

require 'namespaces/metal_array'
require 'namespaces/hash_merger_namespace'
require 'hash_mergers.rb'
require 'ostruct'
Metalware::Utils::DynamicRequire.relative('.')

module Metalware
  module Namespaces
    class Alces
      include Mixins::AlcesStatic

      def initialize(metal_config)
        @metal_config = metal_config
        @dynamic_stack = []
      end

      def render_erb_template(template_string, dynamic_namespace = {})
        run_with_dynamic(dynamic_namespace) do
          Templating::Renderer.replace_erb_with_binding(template_string, binding)
        end
      end

      ##
      # shared hash_merger object which contains a file cache
      #
      def hash_mergers
        @hash_mergers ||= begin
          OpenStruct.new(config: HashMergers::Config.new(metal_config),
                         answer: HashMergers::Answer.new(metal_config))
        end
      end

      ##
      # method_missing is used to access the dynamic namespace
      #
      def method_missing(s, *_a, &_b)
        if respond_to_missing?(s)
          current_dynamic_namespace[s]

        ##
        # TEMPORARY: maintaining partial backwards compatability so config
        # can be accessed directly. This should be removed when possible
        #
        elsif current_dynamic_namespace.key?(:config) && current_dynamic_namespace[:config].respond_to?(s)
          current_dynamic_namespace[:config][s]
        else
          super
        end
      end

      def respond_to_missing?(s, *_a)
        current_dynamic_namespace&.key?(s)
      end

      private

      attr_reader :metal_config, :dynamic_stack

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
