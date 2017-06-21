
require 'configure_command'
require 'constants'


module Metalware
  module Commands
    module Configure

      class Node < ConfigureCommand
        def setup(args, _options)
          @node_name = args.first
        end

        protected

        def answers_file
          File.join(Constants::ANSWERS_PATH, 'nodes', node_name)
        end

        private

        attr_reader :node_name
      end

    end
  end
end
