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

module Metalware
  module Validation
    class Configure
      # TODO: 'choice' is going to be removed as a valid type. Instead the type
      # will that of the data contained. Whether their is any choices will be
      # determined by whether they are supplied.

      # NOTE: Supported types in error.yaml message must be updated manually

      SUPPORTED_TYPES = ['string', 'integer', 'boolean', 'choice'].freeze
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

      def data
        raise ValidationFailure, error_msg unless validate.success?
        raw_data.dup
      end

      private

      attr_reader :config, :raw_data

      def file_path
        @file_path ||= FilePath.new(config)
      end

      def load_configure_file
        Data.load(file_path.configure_file)
      end

      def validate
        @validate ||= begin
          ConfigureSchema.call(data: raw_data)
        end
      end

      def error_msg
        msg_header = 'An error occurred validating the questions. ' \
                     "The following error(s) have been detected: \n"
        msg_header + validate.errors[:data].to_s
      end

      QuestionSchema = Dry::Validation.Schema do
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
      end

      ConfigureSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = ERROR_FILE
          config.namespace = :configure

          def top_level_keys?(data)
            section = Constants::CONFIGURE_SECTIONS.dup.push(:questions)
            (data.keys - section).empty?
          end
        end

        required(:data) do
          top_level_keys? & schema do
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

            # Loops through each section
            ::Metalware::Constants::CONFIGURE_SECTIONS.each do |section|
              required(section) do
                # Loops through each question
                array? & each do
                  schema(QuestionSchema) & \
                    default_type? & choice_with_default? & choice_type?
                end
              end
            end
          end
        end
      end
    end
  end
end
