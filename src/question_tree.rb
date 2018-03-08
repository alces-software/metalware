
# frozen_string_literal: true

require 'rubytree'

module Metalware
  class QuestionTree < Tree::TreeNode
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
      content[:identifier]&.to_sym
    end

    # TODO: Eventually change this to a `question` method once the index's
    # and defaults are rationalised
    def create_question(default, progress_indicator, old_answer)
      Configurator::Question.new(
        default: default,
        properties: content,
        old_answer: old_answer,
        progress_indicator: progress_indicator,
        identifier: identifier
      )
    end
  end
end
