
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

      def template(template_string)
        Templating::Renderer.replace_erb_with_binding(template_string, binding)
      end

      def answer
      end

      private

      attr_reader :config, :recursion_count

      
    end
  end
end