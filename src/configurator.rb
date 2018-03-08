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
require 'active_support/string_inquirer'
require 'highline'
require 'patches/highline'
require 'validation/loader'
require 'validation/saver'
require 'file_path'
require 'group_cache'
require 'configurator/question'

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
      @questions_section = questions_section
      @name = (questions_section == :local ? 'local' : name)
    end

    def configure(answers = nil)
      answers ||= ask_questions
      save_answers(answers)
    end

    private

    attr_reader :alces,
                :highline,
                :questions_section,
                :name

    def loader
      @loader ||= Validation::Loader.new
    end

    def saver
      @saver ||= Validation::Saver.new
    end

    def group_cache
      @group_cache ||= GroupCache.new
    end

    # Whether the answer is saved depends if it matches the default AND
    # if it was previously saved. If there is no old_answer, then the
    # default must be set at a higher level. In this case it shouldn't be
    # saved. If there is an old_answer then it is the default. In this case
    # it needs to be saved again so it is not lost.
    def ask_questions
      idx = 0
      section_question_tree.filtered_each.with_object({}) do |node_q, memo|
        idx += 1
        next unless ask_question_based_on_parent_answer(node_q)
        question = node_q.create_question

        question.default = default_hash[node_q.identifier]
        question.progress_indicator = progress_indicator(idx)
        question.old_answer = old_answers[node_q.identifier]

        raw_answer = question.ask(highline)
        answer = if raw_answer == node_q.default
                   nil # TODO workout whats going on here
                 else
                   raw_answer
                 end
        memo[node_q.identifier] = answer unless answer.nil?
      end
    end

    def ask_question_based_on_parent_answer(node_q)
      # TODO: Use the filter methods on QuestionTree to remove the following
      # logic. The old Tree::TreeNode structure has non-question structural
      # nodes within it that needed to be manually filtered
      # However the new QuestionTree object has filtered enumerators that
      # remove the need for checking if a node is a question
      if node_q.question? && !node_q.parent.question?
        true
      # Conditionally ask the question if the parent answer is truthy
      elsif node_q.parent.answer
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
          raise InternalError, "Unrecognised question section: #{questions_section}"
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

    def progress_indicator(index)
      "(#{index}/#{total_questions})"
    end

    def total_questions
      section_question_tree.questions_length
    end
  end
end
