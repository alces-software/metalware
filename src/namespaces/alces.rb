
# frozen_string_literal: true

require 'exceptions'
require 'templating/renderer'
require 'templating/nil_detection_wrapper'
require 'config'
require 'utils/dynamic_require'
require 'deployment_server'

Metalware::Utils::DynamicRequire.relative('mixins')

require 'namespaces/metal_array'
require 'namespaces/hash_merger_namespace'
require 'namespaces/node'
require 'hash_mergers.rb'
require 'ostruct'
require 'metal_log'

Metalware::Utils::DynamicRequire.relative('.')

module Metalware
  module Namespaces
    class Alces
      include Mixins::AlcesStatic
      class << self
        def alces_new_log
          @alces_new_log ||= MetalLog.new('alces-new')
        end

        LOG_MESSAGE = <<-EOF.strip_heredoc
          Create new Alces namespace. Building multiple namespaces will slow
          down metalware as they do not share a file cache. Only build a new
          namespace when required.
        EOF

        def new(*a)
          alces_new_log.info LOG_MESSAGE
          alces_new_log.info caller
          super
        end
      end

      def initialize(metal_config)
        @metal_config = metal_config
        @dynamic_stack = []
      end

      # TODO: Remove this method, use Config.cache instead
      attr_reader :metal_config

      delegate :config, :answer, to: :scope

      NODE_ERROR = 'Error, a Node is not in scope'

      def node
        raise ScopeError, NODE_ERROR unless scope.is_a? Namespaces::Node
        scope
      end

      GROUP_ERROR = 'Error, a Group is not in scope'

      def group
        raise ScopeError, GROUP_ERROR unless scope.is_a? Namespaces::Group
        scope
      end

      DOUBLE_SCOPE_ERROR = 'A node and group can not both be in scope'

      def scope
        dynamic = current_dynamic_namespace || OpenStruct.new
        raise ScopeError, DOUBLE_SCOPE_ERROR if dynamic.group && dynamic.node
        if dynamic.node
          dynamic.node
        elsif dynamic.group
          dynamic.group
        else
          domain
        end
      end

      def render_erb_template(template_string, dynamic_namespace = {})
        run_with_dynamic(dynamic_namespace) do
          Templating::Renderer
            .replace_erb_with_binding(template_string, wrapped_binding)
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

      attr_reader :dynamic_stack

      def run_with_dynamic(namespace)
        if dynamic_stack.length > Constants::MAXIMUM_RECURSIVE_CONFIG_DEPTH
          raise RecursiveConfigDepthExceededError
        end
        dynamic_stack.push(dynamic_hash(namespace))
        result = yield
        dynamic_stack.pop
        parse_result(result)
      end

      def dynamic_hash(namespace)
        Constants::HASH_MERGER_DATA_STRUCTURE.new(namespace) do |template|
          alces.render_erb_template(template)
        end
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

      def wrapped_binding
        Templating::NilDetectionWrapper.wrap(self)
      end
    end
  end
end
