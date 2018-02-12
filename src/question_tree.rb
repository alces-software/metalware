
require 'rubytree'

module Metalware
  class QuestionTree < Tree::TreeNode
    # The QuestionTree has a few issues when it comes to the root and the
    # first level of TreeNodes. These nodes ARE NOT questions but hold the
    # sections (:domain, :group, ...) Nodes. This means when iterating over
    # the QuestionsTree, the root and first level needs to be skipped.
    # NOTE: This is depth_first ONLY, breadth_first will still be broken
    def each
      super do |question|
        next unless question.question?
        yield question
      end
    end

    def questions_length
      num = 0
      each { |_q| num += 1 }
      num
    end

    def question?
      !!identifier
    end

    def identifiers
      map do |question|
        question.identifier
      end
    end

    def identifier
      content[:identifier]
    end
  end
end

