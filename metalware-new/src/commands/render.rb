
require 'templater'

module Metalware
  module Commands
    class Render
      def initialize(args, _options)
        template_path, maybe_node = args
        templater = Templater::Combiner.new({
          nodename: maybe_node,
        })

        rendered = templater.file(template_path)
        puts rendered
      end
    end
  end
end
