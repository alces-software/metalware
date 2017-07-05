
require 'command_helpers/configure_command'
require 'constants'


module Metalware
  module Commands
    module Configure

      class Node < CommandHelpers::ConfigureCommand
        def setup(args, _options)
          @node_name = args.first
        end

        protected

        def answers_file
          file_name = "#{node_name}.yaml"
          File.join(config.answer_files_path, 'nodes', file_name)
        end

        private

        attr_reader :node_name
      end

    end
  end
end
