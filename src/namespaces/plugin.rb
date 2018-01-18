
# frozen_string_literal: true

module Metalware
  module Namespaces
    Plugin = Struct.new(:plugin) do
      include Mixins::WhiteListHasher

      delegate :name, to: :plugin

      private

      def white_list_for_hasher
        [:name]
      end

      def recursive_white_list_for_hasher
        []
      end
    end
  end
end
