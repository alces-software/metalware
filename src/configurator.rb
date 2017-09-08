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
    class << self
      def for_domain(config:)
        file_path = FilePath.new(config)
        new(
          configure_file: file_path.configure_file,
          questions_section: :domain,
          answers_file: file_path.domain_answers,
          higher_level_answer_files: []
        )
      end

      def for_group(group_name, config:)
        file_path = FilePath.new(config)
        new(
          configure_file: file_path.configure_file,
          questions_section: :group,
          answers_file: file_path.group_answers(group_name),
          higher_level_answer_files: [file_path.domain_answers]
        )
      end

      # Note: This is slightly inconsistent with `for_group`, as that just
      # takes a group name and this takes a Node object (as we need to be able
      # to access the Node's primary group).
      def for_node(node, config:)
        file_path = FilePath.new(config)
        new(
          configure_file: file_path.configure_file,
          questions_section: :node,
          answers_file: file_path.node_answers(node.name),
          higher_level_answer_files: [
            file_path.domain_answers,
            file_path.group_answers(node.primary_group),
          ]
        )
      end
    end

    attr_reader :answers_file

    def initialize(
      highline: HighLine.new,
      configure_file:,
      questions_section:,
      answers_file:,
      higher_level_answer_files:,
      use_readline: true
    )
      @highline = highline
      @configure_file = configure_file
      @questions_section = questions_section
      @answers_file = answers_file
      @higher_level_answer_files = higher_level_answer_files
      @use_readline = use_readline
    end

    def configure(answers = nil)
      answers ||= ask_questions
      save_answers(answers)
    end

    def questions
      @questions ||= questions_in_section
                     .map.with_index do |question, index|
        identifier, properties = question
        create_question(identifier, properties, index + 1)
      end
    end

    private

    attr_reader :highline,
                :configure_file,
                :questions_section,
                :higher_level_answer_files,
                :use_readline

    def questions_in_section
      Data.load(configure_file)[questions_section]
    end

    def old_answers
      @old_answers ||= Data.load(answers_file)
    end

    def ask_questions
      questions.map do |question|
        answer = question.ask(highline)
        answer_pair_to_save(question, answer)
      end.reject(&:nil?).to_h
    end

    def answer_pair_to_save(question, answer)
      if answer == question.default
        # If a question is answered with the default answer, we do not want to
        # save it so that the default answer is always used, whatever that
        # might later be changed to. Note: this means we save nothing if the
        # default is manually re-entered; ideally we would save the input in
        # this case but I can't see a way to tell if input has been entered
        # with HighLine, and this isn't a big issue.
        nil
      else
        [question.identifier, answer]
      end
    end

    def save_answers(answers)
      Data.dump(answers_file, answers)
    end

    def create_question(identifier, properties, index)
      higher_level_answer = higher_level_answer_files.map do |file|
        Data.load(file)[identifier]
      end.reject(&:nil?).last

      # If no answer saved at any higher level, fall back to the default
      # defined for the question in `configure.yaml`, if any.
      default = higher_level_answer.nil? ? properties[:default] : higher_level_answer

      Question.new(
        default: default,
        identifier: identifier,
        properties: properties,
        configure_file: configure_file,
        questions_section: questions_section,
        old_answer: old_answers[identifier],
        use_readline: use_readline,
        progress_indicator: progress_indicator(index)
      )
    end

    def progress_indicator(index)
      "(#{index}/#{total_questions})"
    end

    def total_questions
      questions_in_section.length
    end

    class Question
      VALID_TYPES = [:boolean, :choice, :integer, :string].freeze

      attr_reader \
        :choices,
        :default,
        :identifier,
        :old_answer,
        :progress_indicator,
        :question,
        :required,
        :type,
        :use_readline

      def initialize(
        configure_file:,
        default:,
        identifier:,
        old_answer: nil,
        progress_indicator:,
        properties:,
        questions_section:,
        use_readline:
      )
        @choices = properties[:choices]
        @default = default
        @identifier = identifier
        @old_answer = old_answer
        @progress_indicator = progress_indicator
        @question = properties[:question]
        @required = !properties[:optional]
        @use_readline = use_readline

        @type = type_for(
          properties[:type],
          configure_file: configure_file,
          questions_section: questions_section
        )
      end

      def ask(highline)
        ask_method = "ask_#{type}_question"
        send(ask_method, highline) do |highline_question|
          highline_question.readline = true if use_readline?

          if default_input
            highline_question.default = default_input
          elsif answer_required?
            highline_question.validate = ensure_answer_given
          end
        end
      end

      # Whether an answer to this question is required at this level; an answer
      # will not be required if there is already an answer from the question
      # default or a higher level answer file (the `default`), or if the
      # question is not `required`.
      def answer_required?
        !default && required
      end

      private

      def use_readline?
        # Dont't provide readline bindings for boolean questions, in this case
        # they cause an issue where the question is repeated twice if no/bad
        # input is entered, and they are not really necessary in this case.
        use_readline && type != :boolean
      end

      def default_input
        if !current_answer_value.nil? && type == :boolean
          # Default for a boolean question needs to be set to the input
          # HighLine's `agree` expects, i.e. 'yes' or 'no'.
          current_answer_value ? 'yes' : 'no'
        else
          current_answer_value
        end
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
