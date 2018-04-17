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
require 'data'
require 'dry-validation'

module Metalware
  module Validation
    class Answer
      ERROR_FILE = File.join(File.dirname(__FILE__), 'errors.yaml').freeze

      def initialize(answers, answer_section: nil, question_tree: nil)
        @answers = answers
        @section = answer_section
        @question_tree = question_tree
      end

      def validate
        tests = [
          [:MissingSchema, proc do
            MissingSchema.call(validation_hash)
          end],
          [:AnswerTypeSchema, proc do
            AnswerTypeSchema.call(validation_hash)
          end],
        ]
        tests.each do |(test_name, test_proc)|
          @validation_result = test_proc.call
          @last_ran_test = test_name
          return @validation_result unless @validation_result.success?
        end
        @validation_result
      end

      def error_message
        validate if @validation_result.nil?
        return '' if @validation_result.success?
        msg_header = "Failed to validate answers:\n"
        case @last_ran_test
        when :MissingSchema
          "#{msg_header}" \
          "#{@validation_result.messages[:missing_questions][0].chomp} " \
          "#{@validation_result.output[:missing_questions].join(', ')}"
        when :AnswerTypeSchema
          "#{msg_header}" \
          "A type mismatch has been detected in the following question(s):\n" \
          "#{convert_type_errors(@validation_result).join("\n")}\n"
        end
      end

      def success?
        return true if Constants::SKIP_VALIDATION
        validate if @validation_result.nil?
        @validation_result.success?
      end

      def data
        success? ? answers : (raise ValidationFailure, error_message)
      end

      private

      attr_reader :section, :answers

      def loader
        @loader ||= Validation::Loader.new
      end

      def questions_in_section
        loader.section_tree(section).flatten
      end

      def validation_hash
        @validation_hash ||= begin
          payload = {
            answers: [],
            missing_questions: [],
          }
          answers.each_with_object(payload) do |(question, answer), pay|
            if questions_in_section&.key?(question)
              pay[:answers].push(
                {
                  question: question,
                  answer: answer,
                  type: questions_in_section[question].type,
                }.tap { |h| h[:type] = 'string' if h[:type].nil? }
              )
            else
              pay[:missing_questions].push(question)
            end
          end
        end
      end

      ##
      # When Dry Validation detects a type mismatch, the error message contains
      # the index where the error occurred. This method converts that index to
      # the type-error question(s)
      #
      def convert_type_errors(validation_results)
        validation_results.errors[:answers].keys.map do |error_index|
          validation_results.output[:answers][error_index]
        end
      end

      MissingSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = ERROR_FILE
          config.namespace = 'answer'

          def missing_questions?(value)
            value.empty?
          end
        end

        required(:missing_questions).value(:missing_questions?)
      end

      AnswerTypeSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = ERROR_FILE
          config.namespace = 'answer'

          def answer_type?(value)
            case value[:type]
            when nil || 'string'
              value[:answer].is_a? String
            when 'integer'
              value[:answer].is_a? Integer
            when 'boolean'
              [true, false].include?(value[:answer])
            else
              false
            end
          end
        end

        required(:answers).each(:answer_type?)
      end
    end
  end
end
