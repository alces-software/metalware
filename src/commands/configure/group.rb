
require 'configure_command'
require 'constants'


module Metalware
  module Commands
    module Configure

      class Group < ConfigureCommand
        def setup(args, _options)
          @group_name = args.first
        end

        protected

        def answers_file
          file_name = "#{group_name}.yaml"
          File.join(Constants::ANSWERS_PATH, 'groups', file_name)
        end

        private

        attr_reader :group_name
      end

    end
  end
end
