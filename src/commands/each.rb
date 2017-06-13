
require 'base_command'
require 'templater'

module Metalware
  module Commands
    class Each < BaseCommand
      def setup(args, options)
        @args = args
      end

      def run
        template_path, maybe_node = @args

        template_parameters = {
          nodename: maybe_node,
        }.reject { |param, value| value.nil? }

        Templater.render_to_stdout(config, template_path, template_parameters)
      end
    end
  end
end
