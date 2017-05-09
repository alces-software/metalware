
require 'iterator'
require 'templater'
require 'constants'

module Metalware
  module Commands
    class Hosts
      def initialize(args, options)
        options.default template: 'default'
        @options = options

        node_identifier = args.first
        maybe_node = options.group ? nil : node_identifier
        maybe_group = options.group ? node_identifier : nil

        if options.dry_run
          lambda_proc = -> (template_parameters) {puts_template(template_parameters)}
        else
          lambda_proc = -> (template_parameters) {add(template_parameters)}
        end

        template_parameters = {
          nodename: maybe_node
        }

        Iterator.run(maybe_group, lambda_proc, template_parameters)
      end

      private

      def add(template_parameters)
        append_file = '/etc/hosts'
        Templater::Combiner.new(template_parameters).append(template_path, append_file)
      end

      def puts_template(template_parameters)
        puts Templater::Combiner.new(template_parameters).file(template_path)
      end

      def template_path
        File.join(Constants::REPO_PATH, 'hosts', @options.template)
      end
    end
  end
end
