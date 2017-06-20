
require 'base_command'
require 'configurator'
require 'constants'


module Metalware
  module Commands
    module Configure

      class Node < BaseCommand
        def setup(args, _options)
          @node_name = args.first
        end

        def run
          configurator.configure
        end

        def handle_interrupt(_e)
          abort 'Exiting without saving...'
        end

        private

        attr_reader :node_name

        def configurator
          Configurator.new(
            highline: self,
            configure_file: config.configure_file,
            questions: :node,
            answers_file: answers_file
          )
        end

        def answers_file
          File.join(Constants::ANSWERS_PATH, 'nodes', node_name)
        end
      end

    end
  end
end
