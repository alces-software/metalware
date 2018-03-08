
# frozen_string_literal: true

require 'rubytree'
require 'ostruct'

module Metalware
  class QuestionTree < Tree::TreeNode
    # TODO: `question` isn't super descriptive as the is a QuestionTree
    # object. Maybe `text` would be better?
    delegate :question, :choices, :optional, :type, to: :os_content

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

    def identifier
      os_content.identifier&.to_sym
    end

    # TODO: Eventually change this to a `question` method once the index's
    # and defaults are rationalised
    def create_question(default, progress_indicator, old_answer)
      Configurator::Question.new(
        self,
        default: default,
        old_answer: old_answer,
        progress_indicator: progress_indicator
      )
    end

    private

    # TODO: Stop wrapping the content in the validator, that should really
    # be done within the QuestionTree object. It doesn't hurt, as you can't
    # double wrap and OpenStruct, it just isn't required
    def os_content
      OpenStruct.new(content)
    end
  end
end
