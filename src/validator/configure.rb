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
        configure_results = ConfigureSchema.call(yaml: @yaml)
        if configure_results.success?
          [:domain, :group, :node].each do |section|
            # @yaml[section].each do |identifier, parameters|
            #   payload = {
            #     section: section,
            #     identifier: identifier,
            #     parameters: parameters
            #   }
            #   question_results = QuestionSchema
            # end
          end
        end
        configure_results
      end

      private

      QuestionSchema = Dry::Validation.Schema do
        # validate(valid_top_level_question_keys: :here) do |q|
        #   (q.keys - [:question, :type, :default, :choice, :optional]).empty?
        # end

        #required(:group).value(type?: Hash)
        #required(:domain).value(type?: Hash)
        
        #required(:node).value(type?: Hash)
      end

      ConfigureSchema = Dry::Validation.Schema do
        configure do
          config.messages_file = File.join(File.dirname(__FILE__), "errors.yaml")
          config.namespace = :configure
        end

        # White-lists the keys allowed in the configure.yaml file
        validate(valid_top_level_keys: :yaml) do |yaml|
          (yaml.keys - [:domain, :group, :node, :questions]).empty?
        end

        required(:yaml).schema do 
          required(:domain).value(:hash?)
          required(:group).value(:hash?)
          required(:node).value(:hash?)
        end
      end
    end
  end
end