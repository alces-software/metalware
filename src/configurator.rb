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
require 'group_cache'

HighLine::Question.prepend Metalware::Patches::HighLine::Question
HighLine::Menu.prepend Metalware::Patches::HighLine::Menu

module Metalware
  class Configurator
    class << self
      def for_domain(alces)
        new(
          alces,
          questions_section: :domain
        )
      end

      def for_group(alces, group_name)
        new(
          alces,
          questions_section: :group,
          name: group_name
        )
      end

      # Note: This is slightly inconsistent with `for_group`, as that just
      # takes a group name and this takes a Node object (as we need to be able
      # to access the Node's primary group).
      def for_node(alces, node_name)
        return for_local(alces) if node_name == 'local'
        new(
          alces,
          questions_section: :node,
          name: node_name
        )
      end

      def for_local(alces)
        new(
          alces,
          questions_section: :local
        )
      end

      # Used by the tests to switch readline on and off
      def use_readline
        true
      end
    end

    def initialize(
      alces,
      questions_section:,
      name: nil
    )
      @alces = alces
      @highline = HighLine.new
      @config = Config.new
      @questions_section = questions_section
      @name = (questions_section == :local ? 'local' : name)
    end

    def configure(answers = nil)
      answers ||= ask_questions
      save_answers(answers)
    end

    def questions
      Enumerator.new do |enum|
        idx = 0
        section_question_tree.each do |node_q|
          content = node_q.content
          next if content.section
          content.identifier = content.identifier.to_sym
          content.ask_question = create_question(content, (idx += 1))
          enum << [node_q, content]
        end
      end
    end

    private

    attr_reader :alces,
                :config,
                :highline,
                :questions_section,
                :name

    def loader
      @loader ||= Validation::Loader.new
    end

    def saver
      @saver ||= Validation::Saver.new(config)
    end

    def group_cache
      @group_cache ||= GroupCache.new(config)
    end

    # Whether the answer is saved depends if it matches the default AND
    # if it was previously saved. If there is no old_answer, then the
    # default must be set at a higher level. In this case it shouldn't be
    # saved. If there is an old_answer then it is the default. In this case
    # it needs to be saved again so it is not lost.
    def ask_questions
      questions.with_object({}) do |(node_q, content), memo|
        next unless ask_question_based_on_parent_answer(node_q)
        raw_answer = content.ask_question.ask(highline)
        content.answer = if raw_answer == content.default
                           content.old_answer.nil? ? nil : answer
                         else
                           raw_answer
                         end
        identifier = content.identifier.to_sym
        memo[identifier] = content.answer unless content.answer.nil?
      end
    end

    def ask_question_based_on_parent_answer(node_q)
      # Question nodes hang off a section node (eventually) and are thus asked
      if node_q.parent.content.section
        true
      # If the parent's answer is truthy the child is asked
      elsif node_q.parent.content.answer
        true
      # Otherwise don't ask the question
      else
        false
      end
    end

    def section_question_tree
      @section_question_tree ||= loader.configure_section(questions_section)
    end

    def default_hash
      @default_hash ||= begin
        case questions_section
        when :domain
          alces.domain
        when :group
          alces.groups.find_by_name(name) || create_new_group
        when :node, :local
          alces.nodes.find_by_name(name) || create_orphan_node
        else
          raise internalerror, "unrecognised question section: #{questions_section}"
        end.answer.to_h
      end
    end

    def orphan_warning
      msg = <<-EOF.squish
        Could not find node '#{name}' in genders file. The node will be added
        to the orphan group.
      EOF
      msg += "\n\n" + <<-EOF.squish
        The node will not be removed from the orphan group automatically. The
        behaviour of an orphan node that is later added to a group is undefined.
        A node can be removed from the orphan group by editing:
      EOF
      msg + "\n" + FilePath.group_cache
    end

    def create_new_group
      idx = GroupCache.new.next_available_index
      Namespaces::Group.new(alces, name, index: idx)
    end

    def create_orphan_node
      MetalLog.warn orphan_warning unless questions_section == :local
      group_cache.push_orphan(name)
      Namespaces::Node.create(alces, name)
    end

    def old_answers
      @old_answers ||= loader.section_answers(questions_section, name)
    end

    def save_answers(answers)
      saver.section_answers(answers, questions_section, name)
    end

    def create_question(properties, index)
      default = default_hash[properties.identifier]

      # TODO: Remove default as an input and save the default in the
      # properties object. The same can be done with the old_answer
      # TODO: Break out the Question object into seperate file
      Question.new(
        config: config,
        default: default,
        properties: properties,
        questions_section: questions_section,
        old_answer: old_answers[properties.identifier],
        progress_indicator: progress_indicator(index)
      )
    end

    def progress_indicator(index)
      "(#{index}/#{total_questions})"
    end

    def total_questions
      section_question_tree.size - 1
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
        old_answer: nil,
        progress_indicator:,
        properties:,
        questions_section:
      )
        @choices = properties.choices
        @default = default
        @identifier = properties.identifier
        @old_answer = old_answer
        @progress_indicator = progress_indicator
        @question = properties.question
        @required = !properties.optional

        @type = type_for(
          properties[:type],
          configure_file: Metalware::FilePath.configure_file,
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
