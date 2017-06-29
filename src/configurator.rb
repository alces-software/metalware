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
    def initialize(highline: HighLine.new, configure_file:,
                   questions_section:, answers_file:)
      @highline = highline
      @configure_file = configure_file
      @questions_section = questions_section
      @answers_file = answers_file
    end

    def configure
      answers = ask_questions
      save_answers(answers)
    end

    private

    attr_reader :highline,
      :configure_file,
      :questions_section,
      :answers_file

    def questions
      @questions ||= YAML.load_file(configure_file).
        with_indifferent_access[questions_section].
        map{ |identifier, properties| create_question(identifier, properties) }
    end

    def ask_questions
      questions.map do |question|
        answer = question.ask(highline)
        [question.identifier, answer]
      end.to_h
    end

    def save_answers(answers)
      File.open(answers_file, 'w') do |f|
        f.write(YAML.dump(answers))
      end
    end

    def create_question(identifier, properties)
      Question.new({
          identifier: identifier,
          properties: properties,
          configure_file: configure_file,
          questions_section: questions_section
        }
      )
    end

    class Question
      VALID_TYPES = [:boolean, :choice, :integer, :string]

      attr_reader :identifier, :question, :type, :choices

      def initialize(identifier:, properties:, configure_file:,
                     questions_section:, default: nil)
        @identifier = identifier
        @question = properties[:question]
        @choices = properties[:choices]
        @default = properties[:default]
        @type = type_for(
          properties[:type],
          configure_file: configure_file,
          questions_section: questions_section
        )
      end

      def ask(highline)
        case type
        when :boolean
          highline.agree(question)
        when :choice
          highline.choose(*choices) do |menu|
            menu.prompt = question
            add_default(q)
          end
        when :integer
          highline.ask(question, Integer)  { |q| add_default(q, :integer) }
        else
          highline.ask(question)  { |q| add_default(q) }
        end
      end

      private

      def add_default(question, type = :string)
        unless @default.nil?
          parsed_default = nil
          case type
          when :string
            parsed_default = @default.to_s
          when :integer
            parsed_default = (@default.is_a?(Integer) ? @default : @default.to_i)
          else
            msg = "Unrecognized data type (#{type}) as a default"
            raise UnknownDataTypeError, msg
          end
          question.default = parsed_default
        end
      end

      def type_for(value, configure_file:, questions_section:)
        value = value&.to_sym
        if value.nil?
          :string
        elsif valid_type?(value)
          value
        else
          message = \
            "Unknown question type '#{value}' for " +
            "#{questions_section}.#{identifier} in #{configure_file}"
          raise UnknownQuestionTypeError, message
        end
      end

      def valid_type?(value)
        VALID_TYPES.include?(value)
      end
    end

  end
end
