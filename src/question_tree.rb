
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
        next unless question.should_ask?
        progress = "(#{index + 1}/#{questions_length})"
        yield create_question(question, progress)
      end
    end

    def should_ask?
      # Ask dependent questions who's parent's answer is truthy
      if parent.answer
        true
      # Do not ask dependent questions who's parent's answer is falsy
      elsif parent.question?
        false
      # However always ask if the parent is not a question
      else
        true
      end
    end

    def questions_length
      @questions_length ||= begin
        num = 0
        filtered_each { |_q| num += 1 }
        num
      end
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

    # NOTE: The following methods are used by the iterator and thus do not
    # reference the self object

    def create_question(question, progress_indicator)
      Configurator::Question.new(question, progress_indicator)
    end
  end
end
