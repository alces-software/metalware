
# frozen_string_literal: true

require 'exceptions'
require 'templating/renderer'
require 'nodeattr_interface'
require 'hash_mergers'

module Metalware
  module Namespaces
    class HashMergerNamespace
      include Mixins::WhiteListHasher

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

      def render_erb_template(template, **user_dynamic_namespace)
        alces.render_erb_template(
          template,
          **additional_dynamic_namespace,
          **user_dynamic_namespace
        )
      end

      private

      attr_reader :alces

      def white_list_for_hasher
        respond_to?(:name) ? [:name] : []
      end

      def recursive_white_list_for_hasher
        [:config, :answer]
      end

      def recursive_array_white_list_for_hasher
        []
      end

      def run_hash_merger(hash_obj)
        hash_obj.merge(**hash_merger_input) do |template|
          render_erb_template(template)
        end
      end

      def hash_merger_input
        raise NotImplementedError
      end

      def additional_dynamic_namespace
        raise NotImplementedError
      end
    end
  end
end
