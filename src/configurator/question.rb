
# frozen_string_literal: true

module Metalware
  class Configurator
    class Question
      attr_reader \
        :choices,
        :default,
        :identifier,
        :old_answer,
        :progress_indicator,
        :question,
        :required,
        :type

      def initialize(
        default:,
        old_answer: nil,
        progress_indicator:,
        properties:
      )
        @choices = properties.choices
        @default = default
        @identifier = properties.identifier
        @old_answer = old_answer
        @progress_indicator = progress_indicator
        @question = properties.question
        @required = !properties.optional
        @type = type_for(properties[:type])
      end

      def ask(highline)
        ask_method = choices.nil? ? "ask_#{type}_question" : 'ask_choice_question'
        send(ask_method, highline) { |q| configure_question(q) }
      end

      private

      def configure_question(highline_question)
        highline_question.readline = use_readline?
        highline_question.default = default_input
        if validate_answer_given?
          highline_question.validate = ensure_answer_given
        end
      end

      def validate_answer_given?
        # Do not override built-in HighLine validation for `agree` questions,
        # which will already cause the question to be re-prompted until a valid
        # answer is given (rather than just accepting any non-empty answer, as
        # our `ensure_answer_given` does).
        return false if type.boolean?

        answer_required?
      end

      # Whether an answer to this question is required at this level; an answer
      # will not be required if there is already an answer from the question
      # default or a higher level answer file (the `default`), or if the
      # question is not `required`.
      def answer_required?
        !default && required
      end

      def use_readline?
        # Don't provide readline bindings for boolean questions, in this case
        # they cause an issue where the question is repeated twice if no/bad
        # input is entered, and they are not really necessary in this case.
        return false if type.boolean?

        Metalware::Configurator.use_readline
      end

      def default_input
        type.boolean? ? boolean_default_input : current_answer_value
      end

      def boolean_default_input
        return nil if current_answer_value.nil?

        # Default for a boolean question which has a previous answer should be
        # set to the input HighLine's `agree` expects, i.e. 'yes' or 'no'.
        current_answer_value ? 'yes' : 'no'
      end

      # The answer value this question at this level would currently take.
      def current_answer_value
        old_answer.nil? ? default : old_answer
      end

      def ask_boolean_question(highline)
        highline.agree(question_text + ' [yes/no]') { |q| yield q }
      end

      def ask_choice_question(highline)
        highline.choose(*choices) do |menu|
          menu.prompt = question_text
          yield menu
        end
      end

      def ask_integer_question(highline)
        highline.ask(question_text, Integer) { |q| yield q }
      end

      def ask_string_question(highline)
        highline.ask(question_text) { |q| yield q }
      end

      def question_text
        "#{question.strip} #{progress_indicator}"
      end

      def type_for(value)
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
