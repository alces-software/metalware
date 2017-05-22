
require 'templater'

module Metalware
  module Commands
    class Render
      def initialize(args, _options)
        template_path, maybe_node = args

        template_parameters = {
          nodename: maybe_node,
        }.reject { |param, value| value.nil? }
        templater = Templater.new(template_parameters)

        rendered = templater.file(template_path)
        puts rendered
      end
    end
  end
end
