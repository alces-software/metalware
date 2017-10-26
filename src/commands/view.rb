
# frozen_string_literal: true

require 'json'
require 'command_helpers/alces_command'

module Metalware
  module Commands
    class View < CommandHelpers::BaseCommand
      private

      include CommandHelpers::AlcesCommand

      def run
        pretty_print_json(cli_input_object.to_json)
      end

      def cli_input_object
        if alces_command.is_a?(Namespaces::MetalArray)
          alces_command
        else
          obj = alces_command
          obj.is_a?(Array) ? obj.map(&:to_h) : obj.to_h
        end
      end

      def pretty_print_json(json)
        # Delegate pretty printing with colours to `jq`.
        Open3.popen2(jq_command) do |stdin, stdout|
          stdin.write(json)
          stdin.close
          puts stdout.read
        end
      end

      def jq_command
        "jq . #{colourize_output? ? '--color-output' : ''}"
      end

      def colourize_output?
        # Should colourize the output if we have been forced to do so or we are
        # outputting to a terminal.
        options.color_output || STDOUT.isatty
      end
    end
  end
end
