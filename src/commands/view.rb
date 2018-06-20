
# frozen_string_literal: true

require 'json'

module Metalware
  module Commands
    class View < CommandHelpers::BaseCommand
      private

      attr_reader :command

      def setup
        @command = args.first
      end

      def run
        pretty_print_json(alces.instance_eval(command).to_json)
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
