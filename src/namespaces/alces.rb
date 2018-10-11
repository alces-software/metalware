
# frozen_string_literal: true

require 'exceptions'
require 'templating/renderer'
require 'templating/nil_detection_wrapper'
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

      NODE_ERROR = 'Error, a Node is not in scope'
      GROUP_ERROR = 'Error, a Group is not in scope'
      DOUBLE_SCOPE_ERROR = 'A node and group can not both be in scope'

      delegate :config, :answer, to: :scope

      class << self
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

        def alces_new_log
          @alces_new_log ||= MetalLog.new('alces-new')
        end
      end

      def initialize
        @stacks_hash = {}
      end

      def node
        raise ScopeError, NODE_ERROR unless scope.is_a? Namespaces::Node
        scope
      end

      def group
        raise ScopeError, GROUP_ERROR unless scope.is_a? Namespaces::Group
        scope
      end

      def scope
        dynamic = current_dynamic_namespace || OpenStruct.new
        raise ScopeError, DOUBLE_SCOPE_ERROR if dynamic.group && dynamic.node
        dynamic.node || dynamic.group || domain
      end

      def render_string(template_string, **dynamic_namespace)
        run_with_dynamic(dynamic_namespace) do
          Templating::Renderer
            .replace_erb_with_binding(template_string, wrapped_binding)
        end
      end

      def render_file(template_path, **dynamic_namespace)
        template = File.read(template_path)
        render_string(template, dynamic_namespace)
      rescue StandardError => e
        msg = "Failed to render template: #{template_path}"
        raise e, "#{msg}\n#{e}", e.backtrace
      end

      ##
      # shared hash_merger object which contains a file cache
      #
      def hash_mergers
        @hash_mergers ||= begin
          OpenStruct.new(config: HashMergers::Config.new,
                         answer: HashMergers::Answer.new(alces))
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

      attr_reader :stacks_hash

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
          alces.render_string(template)
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

      def dynamic_stack
        stacks_hash[Thread.current] = [] unless stacks_hash[Thread.current]
        stacks_hash[Thread.current]
      end

      def wrapped_binding
        Templating::NilDetectionWrapper.wrap(self)
      end
    end
  end
end
