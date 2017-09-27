
# frozen_string_literal: true
require 'exceptions'
require 'templating/renderer'

module Metalware
  module Namespaces
    class Alces
      def initialize(config)
        @config = config
        @recursion_count = 0
      end

      def alces
        self
      end

      def render_erb_template(template_string)
        bump_recursion_number do
          Templating::Renderer.replace_erb_with_binding(template_string, binding)
        end
      end

      def answer
      end

      private

      attr_reader :config, :recursion_count

      def bump_recursion_number
        if @recursion_count > Constants::MAXIMUM_RECURSIVE_CONFIG_DEPTH
          raise RecursiveConfigDepthExceededError
        end
        @recursion_count += 1
        result = yield
        @recursion_count -= 1
        result
      end
    end
  end
end