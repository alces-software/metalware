
# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'highline'
require 'patches/highline'

HighLine::Question.prepend Metalware::Patches::HighLine::Question
HighLine::Menu.prepend Metalware::Patches::HighLine::Menu

module Metalware
  class Configurator
    class Question
      def initialize(question_node, progress_indicator)
        @question_node = question_node
        @highline = HighLine.new
        @progress_indicator = progress_indicator
      end

      attr_accessor :default
      delegate :identifier, to: :question_node

      def ask
        method = choices.nil? ? "ask_#{type}_question" : 'ask_choice_question'
        question_node.answer = send(method) { |q| configure_question(q) }
      end

      private

      attr_reader :question_node, :highline, :progress_indicator
      delegate :choices, :optional, :text, to: :question_node

      def configure_question(highline_question)
        highline_question.readline = use_readline?
        highline_question.default = default_input
        validate_highline_answer_given(highline_question)
      end

      def validate_highline_answer_given(highline_question)
        # Do not override built-in HighLine validation for `agree` questions,
        # which will already cause the question to be re-prompted until
        # a valid answer is given (rather than just accepting any non-empty
        # answer, as our `ensure_answer_given` does).
        return if type.boolean?

        # The answer does not need to be given if there is a default or if
        # it is optional
        return if default || optional
        highline_question.validate = ensure_answer_given
      end

      def use_readline?
        # Don't provide readline bindings for boolean questions, in this case
        # they cause an issue where the question is repeated twice if no/bad
        # input is entered, and they are not really necessary in this case.
        return false if type.boolean?

        Metalware::Configurator.use_readline
      end

      def default_input
        return human_readable_boolean_default if type.boolean?
        default.nil? ? default : default.to_s
      end

      # Default for a boolean question which has a previous answer should be
      # set to the input HighLine's `agree` expects, i.e. 'yes' or 'no'.
      def human_readable_boolean_default
        return nil if default.nil?
        default ? 'yes' : 'no'
      end

      def ask_boolean_question
        highline.agree(question_text + ' [yes/no]') { |q| yield q }
      end

      def ask_choice_question
        highline.choose(*choices) do |menu|
          menu.prompt = question_text
          yield menu
        end
      end

      def ask_integer_question
        highline.ask(question_text, Integer) { |q| yield q }
      end

      def ask_string_question
        highline.ask(question_text) { |q| yield q }
      end

      def question_text
        "#{text.strip} #{progress_indicator}"
      end

      def type
        value = question_node.type
        ActiveSupport::StringInquirer.new(value || 'string')
      end

      def ensure_answer_given
        HighLinePrettyValidateProc.new('a non-empty input') do |input|
          !input.empty?
        end
      end

      class HighLinePrettyValidateProc < Proc
        def initialize(print_message, &b)
          # NOTE: print_message is prefaced with "must match" when used by
          # HighLine validate
          @print_message = print_message
          super(&b)
        end

        # HighLine uses the result of inspect to generate the message to display
        def inspect
          @print_message
        end
      end
    end
  end
end
