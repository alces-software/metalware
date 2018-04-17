
# frozen_string_literal: true

require 'answers_table_creator'

module Metalware
  module Commands
    module ViewAnswers
      class Domain < CommandHelpers::BaseCommand
        private

        def run
          puts AnswersTableCreator.new(alces).domain_table
        end

        def dependency_hash
          {
            repo: ['configure.yaml'],
            configure: ['domain.yaml'],
          }
        end
      end
    end
  end
end
