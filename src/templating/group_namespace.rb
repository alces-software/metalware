
# frozen_string_literal: true

module Metalware
  module Templating
    class GroupNamespace
      attr_reader :name

      delegate :to_json, to: :to_h

      def initialize(metalware_config, group_name)
        @metalware_config = metalware_config
        @name = group_name
      end

      # Already migrated as HashMerger
      def answers
        MissingParameterWrapper.new(
          templating_configuration.answers,
          raise_on_missing: true
        )
      end

      # Already migrated as a MetalArray
      def nodes
        NodeattrInterface.nodes_in_primary_group(name).map do |node_name|
          yield templating_config_for_node(node_name)
        end
      end

      def to_h
        ObjectFieldsHasher.hash_object(self, nodes: :nodes_data)
      end

      private

      attr_reader :metalware_config

      # XXX Confusingly the following two methods are both related to
      # 'templating configs' but mean slightly different things by this - this
      # one means the full config that would be available for this node when
      # templating for it, while the next refers to the class for accessing the
      # raw configuration files applicable to this group. This should be
      # improved.
      def templating_config_for_node(node_name)
        RepoConfigParser.parse_for_node(
          node_name: node_name,
          config: metalware_config,
          include_groups: false
        )
      end

      def templating_configuration
        @templating_configuration ||=
          Configuration.for_primary_group(name, config: metalware_config)
      end

      def nodes_data
        nodes { |node| node }
      end
    end
  end
end
