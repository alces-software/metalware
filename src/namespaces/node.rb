
# frozen_string_literal: true

require 'exceptions'
require 'templating/renderer'
require 'nodeattr_interface'
require 'hash_mergers'

module Metalware
  module Namespaces
    class Node
      def initialize(alces, name)
        @metal_config = alces.send(:metal_config)
        @alces = alces
        @name = name
      end

      delegate :config, :answer, to: :hash_merger

      attr_reader :name

      private

      attr_reader :alces, :metal_config

      def genders
        @genders ||= NodeattrInterface.groups_for_node(name)
      end

      def hash_merger
        @hash_merger ||= HashMergers.merge(
          metal_config,
          groups: genders,
          node: name
        ) { |template_string| render_erb_template(template_string) }
      end

      # Sets itself as the node parameter in the dynamic namespace
      #
      def render_erb_template(template)
        alces.render_erb_template(template,
                                  node: self,
                                  config: config,
                                  answer: answer)
      end
    end
  end
end
