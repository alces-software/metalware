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
require 'validation/loader'
require 'validation/saver'
require 'file_path'
require 'node'

HighLine::Question.prepend Metalware::Patches::HighLine::Questions

module Metalware
  class Configurator
    class << self
      def for_domain(config:)
        new(
          config: config,
          questions_section: :domain
        )
      end

      def for_group(group_name, config:)
        new(
          config: config,
          questions_section: :group,
          name: group_name
        )
      end

      # Note: This is slightly inconsistent with `for_group`, as that just
      # takes a group name and this takes a Node object (as we need to be able
      # to access the Node's primary group).
      def for_node(node_name, config:)
        new(
          config: config,
          questions_section: :node,
          name: node_name
        )
      end

      def for_self(config:)
        new(
          config: config,
          questions_section: :self
        )
      end

      # Used by the tests to switch readline on and off
      def use_readline
        true
      end
    end

    def initialize(
      config:,
      questions_section:,
      name: nil
    )
      @highline = HighLine.new
      @config = config
      @questions_section = questions_section
      @name = name
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

    attr_reader :config,
                :highline,
                :questions_section,
                :name

    def loader
      @loader ||= Validation::Loader.new(config)
    end

    def saver
      @saver ||= Validation::Saver.new(config)
    end

    def configure_data
      @configure_data ||= loader.configure_data
    end

    def questions_in_section
      configure_data[questions_section]
    end

    def higher_level_answer_data
      @higher_level_answer_data ||= begin
        case questions_section
        when :domain
          []
        when :group, :self
          [loader.domain_answers]
        when :node
          node = Node.new(config, name)
          [
            loader.domain_answers,
            loader.group_answers(node.primary_group),
          ]
        else
          raise InternalError, "Unrecognised question section: #{questions_section}"
        end
      end
    end

    def old_answers
      @old_answers ||= loader.section_answers(questions_section, name)
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
      saver.section_answers(answers, questions_section, name)
    end

    def create_question(identifier, properties, index)
      higher_level_answer = higher_level_answer_data.map { |d| d[identifier] }
                                                    .reject(&:nil?)
                                                    .last

      # If no answer saved at any higher level, fall back to the default
      # defined for the question in `configure.yaml`, if any.
      default = higher_level_answer.nil? ? properties[:default] : higher_level_answer

      Question.new(
        config: config,
        default: default,
        identifier: identifier,
        properties: properties,
        questions_section: questions_section,
        old_answer: old_answers[identifier],
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
        :type

      def initialize(
        config:,
        default:,
        identifier:,
        old_answer: nil,
        progress_indicator:,
        properties:,
        questions_section:
      )
        @choices = properties[:choices]
        @default = default
        @identifier = identifier
        @old_answer = old_answer
        @progress_indicator = progress_indicator
        @question = properties[:question]
        @required = !properties[:optional]

        @type = type_for(
          properties[:type],
          configure_file: config.configure_file,
          questions_section: questions_section
        )
      end

      def ask(highline)
        ask_method = choices.nil? ? "ask_#{type}_question" : 'ask_choice_question'
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
        Metalware::Configurator.use_readline && type != :boolean
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
