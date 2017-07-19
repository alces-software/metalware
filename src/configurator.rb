# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

require 'active_support/core_ext/hash'
require 'highline'
require 'patches/highline'

HighLine::Question.prepend Metalware::Patches::HighLine::Questions

module Metalware
  class Configurator
    def initialize(
      highline: HighLine.new,
      configure_file:,
      questions_section:,
      answers_file:,
      use_readline: true
    )
      @highline = highline
      @configure_file = configure_file
      @questions_section = questions_section
      @answers_file = answers_file
      @use_readline = use_readline
    end

    def configure
      answers = ask_questions
      save_answers(answers)
    end

    private

    attr_reader :highline,
                :configure_file,
                :questions_section,
                :answers_file,
                :use_readline

    def questions
      @questions ||= questions_in_section
                     .map.with_index do |question, index|
        identifier, properties = question
        create_question(identifier, properties, index + 1)
      end
    end

    def questions_in_section
      Data.load(configure_file)[questions_section]
    end

    def old_answers
      @old_answers ||= Data.load(answers_file)
    end

    def ask_questions
      questions.map do |question|
        answer = question.ask(highline)
        [question.identifier, answer]
      end.to_h
    end

    def save_answers(answers)
      Data.dump(answers_file, answers)
    end

    def create_question(identifier, properties, index)
      Question.new(
        identifier: identifier,
        properties: properties,
        configure_file: configure_file,
        questions_section: questions_section,
        old_answer: old_answers[identifier],
        use_readline: use_readline,
        question: question_text(properties, index)
      )
    end

    def question_text(properties, index)
      progress_indicator = "(#{index}/#{total_questions})"
      "#{properties[:question].strip} #{progress_indicator}"
    end

    def total_questions
      questions_in_section.length
    end

    class Question
      VALID_TYPES = [:boolean, :choice, :integer, :string].freeze

      attr_reader :identifier,
                  :question,
                  :type,
                  :choices,
                  :default,
                  :required,
                  :use_readline

      def initialize(
        identifier:,
        question:,
        properties:,
        configure_file:,
        questions_section:,
        old_answer: nil,
        use_readline:
      )
        @identifier = identifier
        @question = question
        @choices = properties[:choices]
        @required = !properties[:optional]
        @use_readline = use_readline

        @type = type_for(
          properties[:type],
          configure_file: configure_file,
          questions_section: questions_section
        )

        @default = determine_default(
          question_default: properties[:default],
          old_answer: old_answer
        )
      end

      def ask(highline)
        ask_method = "ask_#{type}_question"
        send(ask_method, highline) do |highline_question|
          highline_question.readline = true if use_readline?

          if default.present?
            highline_question.default = default
          elsif required
            highline_question.validate = ensure_answer_given
          end
        end
      end

      private

      def use_readline?
        # Dont't provide readline bindings for boolean questions, in this case
        # they cause an issue where the question is repeated twice if no/bad
        # input is entered, and they are not really necessary in this case.
        use_readline && type != :boolean
      end

      def ask_boolean_question(highline)
        highline.agree(question + ' [yes/no]') { |q| yield q }
      end

      def ask_choice_question(highline)
        highline.choose(*choices) do |menu|
          menu.prompt = question
          yield menu
        end
      end

      def ask_integer_question(highline)
        highline.ask(question, Integer) { |q| yield q }
      end

      def ask_string_question(highline)
        highline.ask(question) { |q| yield q }
      end

      def type_for(value, configure_file:, questions_section:)
        value = value&.to_sym
        if value.nil?
          :string
        elsif valid_type?(value)
          value
        else
          message = \
            "Unknown question type '#{value}' for " \
            "#{questions_section}.#{identifier} in #{configure_file}"
          raise UnknownQuestionTypeError, message
        end
      end

      def valid_type?(value)
        VALID_TYPES.include?(value)
      end

      def determine_default(question_default:, old_answer:)
        # XXX Remove validation/conversion here and do in earlier step for
        # validating `configure.yaml`? Similarly in `type_for` etc.
        raw_default = old_answer.nil? ? question_default : old_answer
        unless raw_default.nil?
          case type
          when :string
            raw_default.to_s
          when :integer
            raw_default.to_i
          when :boolean
            # Default for a boolean question needs to be set to the input
            # HighLine's `agree` expects, i.e. 'yes' or 'no'.
            raw_default ? 'yes' : 'no'
          else
            msg = "Unrecognized data type (#{type}) as a default"
            raise UnknownDataTypeError, msg
          end
        end
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
