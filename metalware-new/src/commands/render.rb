
require 'templater'

module Metalware
  module Commands
    class Render
      def initialize(args, _options)
        template_path, maybe_node = args

        template_parameters = {
          nodename: maybe_node,
        }.reject { |param, value| value.nil? }

        Templater.render_to_stdout(template_path, template_parameters)
      end
    end
  end
end
