
# frozen_string_literal: true

require 'answers_table_creator'

module Metalware
  module Commands
    module ViewAnswers
      class Node < CommandHelpers::BaseCommand
        private

        attr_reader :node_name

        def setup(args, _options)
          @node_name = args.first
        end

        def run
          puts AnswersTableCreator.new(config).node_table(node_name)
        end

        def dependency_hash
          dependency_specifications.for_node_in_configured_group(node_name)
        end
      end
    end
  end
end
