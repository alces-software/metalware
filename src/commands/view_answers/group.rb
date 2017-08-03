
# frozen_string_literal: true

require 'answers_table_creator'

module Metalware
  module Commands
    module ViewAnswers
      class Group < CommandHelpers::BaseCommand
        private

        attr_reader :group_name

        def setup(args, _options)
          @group_name = args.first
        end

        def run
          puts AnswersTableCreator.new(config).primary_group_table(group_name)
        end

        def dependency_hash
          {
            repo: ['configure.yaml'],
            configure: ['domain.yaml', "groups/#{group_name}.yaml"],
          }
        end
      end
    end
  end
end
