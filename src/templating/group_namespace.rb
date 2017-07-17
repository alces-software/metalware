
# frozen_string_literal: true

module Metalware
  module Templating
    class GroupNamespace
      attr_reader :name

      def initialize(metalware_config, group_name)
        @metalware_config = metalware_config
        @name = group_name
      end

      def answers
        MissingParameterWrapper.new(
          templating_configuration.answers,
          raise_on_missing: true
        )
      end

      def nodes
        NodeattrInterface.nodes_in_group(name).each do |node_name|
          yield templating_config_for_node(node_name)
        end
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
          config: metalware_config
        )
      end

      def templating_configuration
        @templating_configuration ||=
          Configuration.for_primary_group(name, config: metalware_config)
      end
    end
  end
end
