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
    class Configure
      def initialize(file)
        @yaml = Data.load(file)
      end

      def validate
        ConfigureSchema.call(yaml: @yaml)
      end

      private



      # TODO: These our temporary messages for the additional validations I have
      # added. Ideally these will be moved to a separate file
      # http://dry-rb.org/gems/dry-validation/error-messages/
      def self.messages
        super.merge( en: { errors: {
          valid_top_level_keys: 'Configure.yaml must only contain domain, '\
                                'group, node and questions',
          question_block?: 'Is not a valid block of questions to be asked',
          valid_top_level_question_keys: 'The only top level question keys '\
            "allowed are: question, type, default, choice, and optional"
        
        }})
      end

      QuestionBlockSchema = Dry::Validation.Schema do
        required(:domain).value(type?: Hash)
        #required(:question_block_input).value(:valid_question?)
      end

      QuestionSchema = Dry::Validation.Schema do
        validate(valid_top_level_question_keys: [:domain, :group, :node]) do |q|
          (q.keys - [:question, :type, :default, :choice, :optional]).empty?
        end

        #required(:domain).value(:valid_question?)
      end

      ConfigureSchema = Dry::Validation.Schema do
        # White-lists the keys allowed in the configure.yaml file
        validate(valid_top_level_keys: :yaml) do |yaml|
          (yaml.keys - [:domain, :group, :node, :questions]).empty?
        end

        # Note this is the 'yaml' file input converted to a hash 
        required(:yaml).schema do
          required(:domain).value(type?: Hash)
          required(:group).value(type?: Hash)
          required(:node).value(type?: Hash)
        end
        required(:yaml).schema(QuestionSchema)
      end
    end
  end
end