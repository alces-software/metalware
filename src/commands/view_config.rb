
# frozen_string_literal: true

require 'json'

module Metalware
  module Commands
    class ViewConfig < CommandHelpers::BaseCommand
      private

      attr_reader :node_name

      def setup
        @node_name = args.first
      end

      def run
        pretty_print_json(templating_config_json)
      end

      def dependency_hash
        # If we want to view templating config for particular node,
        # then that node must be part of a configured group.
        if node_name
          dependency_specifications.for_node_in_configured_group(node_name)
        else
          {}
        end
      end

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
