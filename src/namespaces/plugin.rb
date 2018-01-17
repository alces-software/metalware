
# frozen_string_literal: true

module Metalware
  module Namespaces
    Plugin = Struct.new(:plugin) do
      delegate :name, to: :plugin
    end
  end
end
