
require 'templater'

module Metalware
  module Commands
    class Render
      def initialize(args, _options)
        template_path, maybe_node = args

        template_parameters = {
          nodename: maybe_node,
        }.reject { |param, value| value.nil? }

        rendered = Templater.file(template_path, template_parameters)
        puts rendered
      end
    end
  end
end
