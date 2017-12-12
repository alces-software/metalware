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

require 'exceptions'
require 'file_path'
require 'data'
require 'dry-validation'
require 'constants'
require 'rubytree'
require 'stringio'

module Metalware
  module Validation
    class Configure
      # TODO: 'choice' is going to be removed as a valid type. Instead the type
      # will that of the data contained. Whether their is any choices will be
      # determined by whether they are supplied.

      # NOTE: Supported types in error.yaml message must be updated manually

      SUPPORTED_TYPES = ['string', 'integer', 'boolean'].freeze
      ERROR_FILE = File.join(File.dirname(__FILE__), 'errors.yaml').freeze

      def self.type_check(type, value)
        case type
        when 'string', nil
          value.is_a?(String)
        when 'integer'
          value.is_a?(Integer)
        when 'boolean'
          [true, false].include?(value)
        else
          false
        end
      end

      def initialize(config, data_hash = nil)
        @config = config
        @raw_data = (data_hash || load_configure_file).freeze
      end

      # TODO: Rethink the raw input, it is a bit odd on closer inspection
      # It will need to be reworked for Tree. Consider removing or better
      # mocking in the test
      def data(raw: false)
        return return_data(raw) unless config.validation
        raise_error_if_validation_failed
        tree
      end

      private

      attr_reader :config, :raw_data

      def load_configure_file
        Data.load(FilePath.configure_file)
      end

      attr_accessor :failed_validation

      def raise_error_if_validation_failed
        return if success?
        prune_successful_leaves
        io = StringIO.new
        print_error_node(io)
        tree.print_tree(0, nil, print_error_node(io))
        io.rewind
        raise ValidationFailure, io.read
      end

      def print_error_node(io)
        lambda do |node, prefix|
          io.puts "#{prefix} #{node.name}"
          result = node.content[:result]
          io.puts result.errors.to_s unless result.success?
        end
      end

      def success?
        tree.content[:pass]
      end

      def tree
        @tree ||= begin
          root_hash = {
            pass: true,
            result: TopLevelSchema.call(data: raw_data),
          }
          Tree::TreeNode.new('ROOT', root_hash).tap do |root|
            add_children(root, root) do
              Constants::CONFIGURE_SECTIONS.map do |section|
                make_section_node(root, section)
              end
            end
          end
        end
      end

      def make_section_node(root, section)
        data = {
          section: section,
          result: DependantSchema.call(dependent: raw_data[section])
        }
        node_s = Tree::TreeNode.new(section.upcase, data)
        add_children(root, node_s) do
          raw_data[section].map { |q| make_question_node(root, q) }
        end
      end

      def make_question_node(root, **question)
        result_h = { result: QuestionSchema.call(question: question) }
        data = (question.is_a?(Hash) ? question.merge(result_h) : result_h)
        node_q = Tree::TreeNode.new(data[:identifier].to_s, data)
        add_children(root, node_q) do
          question[:dependent]&.map do |sub_question|
            make_question_node(root, **sub_question)
          end
        end
      end

      def add_children(root, parent)
        if parent.content[:result].success?
          yield&.each { |child| parent << child }
        else
          root.content[:pass] = false
        end
        parent
      end

      def prune_successful_leaves
        # Postorder sort starts at the leaves and works its way in
        tree.postordered_each do |node|
          node.remove_from_parent! if begin
            if node.has_children? # Only remove leaves
              false
            elsif node.content&.[](:result).nil? # Remove section/root nodes
              true
            elsif node.content[:result].success? # Remove successful nodes
              true
            else
              false
            end
          end
        end
      end

      DependantSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = ERROR_FILE
          config.namespace = :configure
        end

        optional(:dependent) { array? && (each { hash? }) }
      end

      QuestionFieldSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = ERROR_FILE
          config.namespace = :configure

          def supported_type?(value)
            SUPPORTED_TYPES.include?(value)
          end

          def default?(value)
            return true if value.is_a?(String)
            value.respond_to?(:empty?) ? value.empty? : true
          end
        end

        required(:identifier) { filled? & str? }
        required(:question) { filled? & str? }
        optional(:optional) { bool? }
        optional(:type) { supported_type? }
        optional(:default) { default? }
        optional(:choice) { array? }
        schema(DependantSchema)
      end

      QuestionSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = ERROR_FILE
          config.namespace = :configure

          def default_type?(value)
            default = value[:default]
            type = value[:type]
            return true if default.nil?
            ::Metalware::Validation::Configure.type_check(type, default)
          end

          def choice_with_default?(value)
            return true if value[:choice].nil? || value[:default].nil?
            return false unless value[:choice].is_a?(Array)
            value[:choice].include?(value[:default])
          end

          def choice_type?(value)
            return true if value[:choice].nil?
            return false unless value[:choice].is_a?(Array)
            value[:choice].each do |choice|
              type = value[:type]
              r = ::Metalware::Validation::Configure.type_check(type, choice)
              return false unless r
            end
            true
          end
        end

        required(:question) do
          default_type? & \
            choice_with_default? & \
            choice_type? & \
            schema(QuestionFieldSchema)
        end
      end

      TopLevelSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = ERROR_FILE
          config.namespace = :configure

          def top_level_keys?(data)
            section = Constants::CONFIGURE_SECTIONS.dup.push(:questions)
            (data.keys - section).empty?
          end
        end

        required(:data) { top_level_keys? }
      end
    end
  end
end
