
require 'commands/base_command'
require 'constants'
require 'iterator'
require 'nodes'
require 'templater'

module Metalware
  module Commands
    class Hosts < BaseCommand
      HOSTS_FILE = '/etc/hosts'

      private

      def setup(args, options)
        options.default template: 'default'
        @options = options

        node_identifier = args.first
        @nodes = Nodes.create(@config, node_identifier, options.group)
      end

      def run
        add_nodes_to_hosts
      end

      def add_nodes_to_hosts
        @nodes.template_each do |parameters|
          if @options.dry_run
            Templater.render_to_stdout(template_path, parameters)
          else
            Templater.render_and_append_to_file(template_path, HOSTS_FILE, parameters)
          end
        end
      end

      def template_path
        File.join(Constants::REPO_PATH, 'hosts', @options.template)
      end
    end
  end
end
