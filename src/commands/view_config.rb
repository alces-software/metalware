
# frozen_string_literal: true

require 'json'

module Metalware
  module Commands
    class ViewConfig < CommandHelpers::BaseCommand
      def setup(args, options)
        @node_name = args.first
        @options = options
      end

      def run
        pretty_print_json(templating_config_json)
      end

      private

      attr_reader :node_name, :options

      def templating_config_json
        Metalware::Templating::RepoConfigParser.parse_for_node(
          node_name: node_name,
          config: config,
          include_groups: options.include_groups
        ).to_json
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
        # Do not colourize the output if we're not outputting to a terminal, so
        # don't get escape sequences piped to next command.
        "jq . #{STDOUT.isatty ? '--color-output' : ''}"
      end
    end
  end
end
