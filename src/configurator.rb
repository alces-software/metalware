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
require 'validation/loader'
require 'validation/saver'
require 'file_path'
require 'group_cache'
require 'configurator/question'

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
      @questions_section = questions_section
      @name = (questions_section == :local ? 'local' : name)
    end

    def configure(answers = nil)
      answers ||= ask_questions
      save_answers(answers)
    end

    private

    attr_reader :alces,
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

    def ask_questions
      memo = {}
      section_question_tree.ask_questions do |question|
        identifier = question.identifier
        question.default = default_hash[identifier]
        memo[identifier] = question.ask
      end
      memo
    end

    def save_answers(raw_answers)
      answers = reject_non_saved_answers(raw_answers)
      saver.section_answers(answers, questions_section, name)
    end

    def reject_non_saved_answers(answers)
      answers.reject do |identifier, answer|
        higher_level_answers[identifier] == answer
      end
    end

    def higher_level_answers
      @higher_level_answers ||= begin
        case configure_object
        when Namespaces::Domain
          alces.questions.root_defaults
        when Namespaces::Group
          alces.domain.answer
        else
          {}
        end
      end
    end

    def section_question_tree
      alces.questions.section_tree(questions_section)
    end

    def configure_object
      @configure_object ||= begin
        case questions_section
        when :domain
          alces.domain
        when :group
          alces.groups.find_by_name(name) || create_new_group
        when :node, :local
          alces.nodes.find_by_name(name) || create_orphan_node
        else
          raise InternalError, "Unrecognised question section: #{questions_section}"
        end
      end
    end

    def default_hash
      @default_hash ||= configure_object.answer.to_h
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
  end
end
