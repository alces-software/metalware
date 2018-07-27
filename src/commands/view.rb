
# frozen_string_literal: true

require 'command_helpers/alces_command'
require 'command_helpers/inspect_command'

module Metalware
  module Commands
    class View < CommandHelpers::InspectCommand
      private

      include CommandHelpers::AlcesCommand

      ARRAY_TYPES = [Array, Namespaces::AssetArray].freeze

      def run
        pretty_print_json(cli_input_object.to_json)
      end

      def cli_input_object
        data = alces_command
        if data.is_a?(Namespaces::MetalArray)
          data
        elsif ARRAY_TYPES.include?(data.class)
          data.map(&:to_h)
        elsif data.respond_to?(:to_h)
          data.to_h
        else
          data
        end
      end
    end
  end
end
