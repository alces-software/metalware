
# frozen_string_literal: true

require 'rubytree'
require 'ostruct'

module Metalware
  class QuestionTree < Tree::TreeNode
    attr_accessor :answer

    BASE_TRAVERSALS = [
      :each,
      :breadth_each,
      :postordered_each,
      :preordered_each,
    ].freeze

    BASE_TRAVERSALS.each do |base_method|
      define_method(:"filtered_#{base_method}") do |&block|
        questions = public_send(base_method).find_all(&:question?)
        block ? questions.each { |q| block.call(q) } : questions.to_enum
      end
    end

    def ask_questions
      filtered_each.with_index do |question, index|
        next unless ask_conditional_question?(question)
        yield(question, index + 1)
      end
    end

    def questions_length
      num = 0
      filtered_each { |_q| num += 1 }
      num
    end

    def question?
      !!identifier
    end

    def identifiers
      filtered_each.map(&:identifier)
    end

    # START REMAPPING 'content' to variable names
    delegate :choices, :optional, :type, to: :os_content

    def identifier
      os_content.identifier&.to_sym
    end

    def text
      os_content.question
    end

    def yaml_default
      os_content.default
    end
    # END REMAPPING CONTENT

    # TODO: Eventually change this to a `question` method once the index's
    # and defaults are rationalised
    def create_question
      Configurator::Question.new(self)
    end

    def section_tree(section)
      root.children.find { |c| c.name == section }
    end

    def root_defaults
      @root_defaults ||= begin
        section_tree(:domain).filtered_each.reduce({}) do |memo, question|
          memo.merge(question.identifier => question.yaml_default)
        end
      end
    end

    def flatten
      filtered_each.reduce({}) do |memo, node|
        memo.merge(node.identifier => node)
      end
    end

    private

    # TODO: Stop wrapping the content in the validator, that should really
    # be done within the QuestionTree object. It doesn't hurt, as you can't
    # double wrap and OpenStruct, it just isn't required
    def os_content
      OpenStruct.new(content)
    end

    # NOTE: This method is used by the iterator and thus DOES NOT reference
    # the "self" object. Instead it should use the question passed to it
    def ask_conditional_question?(question)
      # Ask the question if the parent has a truthy answer
      if question.parent.answer
        true
      # Ask the question if the parent isn't a question (e.g. a section)
      elsif !question.parent.question?
        true
      # Otherwise don't ask the question
      else
        false
      end
    end
  end
end
