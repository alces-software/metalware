
# frozen_string_literal: true

require 'terminal-table'
require 'validation/loader'

module Metalware
  class AnswersTableCreator
    def initialize(alces)
      @alces = alces
    end

    def domain_table
      answers_table
    end

    def group_table(group_name)
      answers_table(group_name: group_name)
    end

    def node_table(node_name)
      group_name = alces.nodes.find_by_name(node_name).group.name
      answers_table(group_name: group_name, node_name: node_name)
    end

    private

    attr_reader :alces

    def answers_table(group_name: nil, node_name: nil)
      Terminal::Table.new(
        headings: headings(group_name: group_name, node_name: node_name),
        rows: rows(group_name: group_name, node_name: node_name)
      )
    end

    def headings(group_name:, node_name:)
      [
        'Question',
        'Domain',
        group_name ? "Group: #{group_name}" : nil,
        node_name ?  "Node: #{node_name}" : nil,
      ].reject(&:nil?)
    end

    def rows(group_name:, node_name:)
      question_identifiers.map do |identifier|
        [
          identifier,
          domain_answer(question: identifier),
          group_answer(question: identifier, group_name: group_name),
          node_answer(question: identifier, node_name: node_name),
        ].reject(&:nil?)
      end
    end

    def question_identifiers
      @question_identifiers ||= Metalware::Validation::Loader.new
                                                             .question_tree
                                                             .identifiers
                                                             .sort
                                                             .uniq
    end

    def domain_answer(question:)
      format_answer(question: question, namespace: alces.domain)
    end

    def group_answer(question:, group_name:)
      return nil unless group_name
      format_answer(
        question: question,
        namespace: alces.groups.find_by_name(group_name)
      )
    end

    def node_answer(question:, node_name:)
      return nil unless node_name
      format_answer(
        question: question,
        namespace: alces.nodes.find_by_name(node_name)
      )
    end

    def format_answer(question:, namespace:)
      # `inspect` the answer to get it with an indication of its type, so e.g.
      # strings are wrapped in quotes, and can distinguish from integers etc.
      namespace.answer.to_h[question.to_sym].inspect
    end
  end
end
