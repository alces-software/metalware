
require 'rubytree'

module Metalware
  class QuestionTree < Tree::TreeNode
    BASE_TRAVERSALS = [
      :each,
      :breadth_each,
      :postordered_each,
      :preordered_each
    ]

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
      filtered_each.map { |q| q.identifier }
    end

    def identifier
      content[:identifier]
    end
  end
end

