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
require 'validator/base_validator'
require 'utils'

module Metalware
  module Validator
    class Configure < BaseValidator
      def initialize(path)
        @configure_hash = Utils.safely_load_yaml(path)
                               .deep_transform_keys{ |k| k.to_sym }
        freeze
      end

      private

      attr_reader :configure_hash

      def validate
        tests = [
          lambda() { valid_top_level_keys? },
          lambda() { valid_questions?(:domain) },
          lambda() { valid_questions?(:group) },
          lambda() { valid_questions?(:node) }
        ]
        valid_tests?(tests)
      end

      def valid_top_level_keys?
        valid_keys = [:questions, :domain, :group, :node]
        (@configure_hash.keys - valid_keys).empty?
      end

      def valid_questions?(section)
        @configure_hash[section].each do |_question, properties|
          default = properties[:default]
          type = properties[:type]
          return false unless valid_default?(type, default) unless default.nil?
        end
        true
      end

      def valid_default?(type, default)
        type = "string" if type.nil?
        case type
        when "string"
          default.is_a?(String)
        else
          raise ValidatorInternalError, "Can not validate configure.yaml"
        end
      end
    end
  end
end