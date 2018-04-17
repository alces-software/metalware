# frozen_string_literal: true

module Metalware
  class Configurator
    class << self
      def for_domain(alces)
        new(
          alces,
          questions_section: :domain
        )
      end

      def for_group(alces, group_name)
        new(
          alces,
          questions_section: :group,
          name: group_name
        )
      end

      def for_node(alces, node_name)
        return for_local(alces) if node_name == 'local'
        new(
          alces,
          questions_section: :node,
          name: node_name
        )
      end

      def for_local(alces)
        new(
          alces,
          questions_section: :local
        )
      end

      # Used by the tests to switch readline on and off
      def use_readline
        true
      end
    end
  end
end
