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
  module Validator
    class Answer
      ERROR_FILE = File.join(File.dirname(__FILE__), 'errors.yaml').freeze

      def initialize(metalware_config, answer_file)
        @config = metalware_config
        self.section = answer_file
        self.answers = answer_file
        set_questions
      end

      def validate
        tests = [
          proc { AnswerBasicSchema.call(answers: @answers) },
          proc { MissingSchema.call(validation_hash) },
          proc { AnswerTypeSchema.call(validation_hash) },
        ]
        tests.each do |t|
          result = t.call
          return result unless result.success?
          @last_test_ran = result
        end
        @last_test_ran
      end

      private

      attr_reader :section, :config, :answers, :questions

      def section=(answer_file)
        @section = begin
          if answer_file == 'domain.yaml'
            :domain
          elsif /^groups\/.+/.match?(answer_file)
            :group
          elsif /^nodes\/.+/.match?(answer_file)
            :nodes
          else
            msg = "Can not determine question section for #{answer_file}"
            raise ValidationInternalError, msg
          end
        end
      end

      def answers=(answer_file)
        file = File.join(config.answer_files_path, "#{answer_file}.yaml")
        @answers = Data.load(file)
      end

      def set_questions
        file = File.join(config.repo_path, 'configure.yaml')
        @questions = Data.load(file)
      end

      def validation_hash
        @validation_hash ||= begin
          payload = {
            answers: [],
            missing_questions: [],
          }
          answers.each_with_object(payload) do |(question, answer), pay|
            if questions[section].key?(question)
              pay[:answers].push(
                {
                  question: question,
                  answer: answer,
                  type: questions[section][question][:type],
                }.tap { |h| h[:type] = 'string' if h[:type].nil? }
              )
            else
              pay[:missing_questions].push(question)
            end
          end
        end
      end

      AnswerBasicSchema = Dry::Validation.Schema do
        required(:answers).value(:hash?)
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
