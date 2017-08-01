
# frozen_string_literal: true

require 'answers_table_creator'

module Metalware
  module Commands
    module ViewAnswers
      class Domain < CommandHelpers::BaseCommand
        def setup(_args, _options); end

        def run
          puts AnswersTableCreator.new(config).domain_table
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