
require 'iterator'
require 'templater'
require 'constants'
require 'nodes'

module Metalware
  module Commands
    class Hosts
      HOSTS_FILE = '/etc/hosts'

      def initialize(args, options)
        setup(args, options)
        add_nodes_to_hosts
      end

      private

      def setup(args, options)
        options.default template: 'default'
        @options = options

        config = Config.new(options.config)
        node_identifier = args.first
        @nodes = Nodes.create(config, node_identifier, options.group)
      end

      def add_nodes_to_hosts
        @nodes.template_each do |templater|
          if @options.dry_run
            templater.file(template_path)
          else
            templater.append(template_path, HOSTS_FILE)
          end
        end
      end

      def template_path
        File.join(Constants::REPO_PATH, 'hosts', @options.template)
      end
    end
  end
end
