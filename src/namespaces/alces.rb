
# frozen_string_literal: true

require 'exceptions'
require 'templating/renderer'
require 'config'
require 'utils/dynamic_require'
require 'deployment_server'

Metalware::Utils::DynamicRequire.relative('mixins')

require 'namespaces/metal_array'
require 'namespaces/hash_merger_namespace'
require 'namespaces/node'
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
        # Renders against a domain scope by default
        redirect_off = !metal_config.alces_default_to_domain_scope
        if dynamic_namespace.key?(:config) || redirect_off
          run_with_dynamic(dynamic_namespace) do
            Templating::Renderer
              .replace_erb_with_binding(template_string, binding)
          end
        else
          domain.render_erb_template(template_string, dynamic_namespace)
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
        respond_to_missing?(s) ? current_dynamic_namespace[s] : super
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
        dynamic_namespace =
          Constants::HASH_MERGER_DATA_STRUCTURE.new(namespace)
        dynamic_stack.push(dynamic_namespace)
        result = yield
        dynamic_stack.pop
        parse_result(result)
      end

      def parse_result(result)
        case result.strip
        when 'true'
          true
        when 'false'
          false
        when 'nil'
          nil
        when /\A\d+\Z/
          result.to_i
        else
          result
        end
      end

      def current_dynamic_namespace
        dynamic_stack.last
      end
    end
  end
end
