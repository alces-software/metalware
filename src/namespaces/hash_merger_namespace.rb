
# frozen_string_literal: true

require 'exceptions'
require 'templating/renderer'
require 'nodeattr_interface'
require 'hash_mergers'

module Metalware
  module Namespaces
    class HashMergerNamespace
      def initialize(alces, name = nil)
        @alces = alces
        @name = name
      end

      def config
        @config ||= run_hash_merger(alces.hash_mergers.config)
      end

      def answer
        @answer ||= run_hash_merger(alces.hash_mergers.answer)
      end

      private

      attr_reader :alces

      def run_hash_merger(hash_obj)
        hash_obj.merge(**hash_merger_input, &template_block)
      end

      def hash_merger_input
        raise NotImplementedError
      end

      def template_block
        lambda do |template|
          alces.render_erb_template(
            template,
            config: config,
            answer: answer,
            **additional_dynamic_namespace
          )
        end
      end

      def additional_dynamic_namespace
        raise NotImplementedError
      end
    end
  end
end
