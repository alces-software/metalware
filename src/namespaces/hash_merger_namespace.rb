
# frozen_string_literal: true

require 'exceptions'
require 'templating/renderer'
require 'nodeattr_interface'
require 'hash_mergers'

module Metalware
  module Namespaces
    class HashMergerNamespace
      def initialize(alces, name = nil)
        @metal_config = alces.send(:metal_config)
        @alces = alces
        @name = name
      end

      delegate :config, :answer, to: :hash_merger

      private

      attr_reader :alces, :metal_config

      def hash_merger
        @hash_merger ||= HashMergers.merge(
          metal_config,
          **hash_merger_input
        ) { |template_string| render_erb_template(template_string) }
      end

      def hash_merger_input
        raise NotImplementedError
      end

      def render_erb_template(template)
        alces.render_erb_template(template,
                                  config: config,
                                  answer: answer,
                                  **additional_dynamic_namespace)
      end

      def additional_dynamic_namespace
        raise NotImplementedError
      end
    end
  end
end
