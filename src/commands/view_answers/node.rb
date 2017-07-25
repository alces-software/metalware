
# frozen_string_literal: true

require 'answers_table_creator'

module Metalware
  module Commands
    module ViewAnswers
      class Node < CommandHelpers::BaseCommand
        def setup(args, _options)
          @node_name = args.first
        end

        def run
          puts AnswersTableCreator.new(config).node_table(node_name)
        end

        def dependency_hash
          {
            repo: ['configure.yaml'],
            configure: ['domain.yaml', "groups/#{group_name}.yaml"],
          }
        end

        private

        attr_reader :node_name

        def group_name
          node.primary_group
        end

        def node
          Metalware::Node.new(config, node_name, should_be_configured: true)
        end
      end
    end
  end
end
