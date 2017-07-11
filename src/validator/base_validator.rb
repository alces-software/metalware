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

module Metalware
  module Validator
    class BaseValidator
      def initialize(*_a)
        raise NotImplementedError
      end

      def valid?
        !!validate
      end

      private

      def validate
        raise NotImplementedError
      end

      # Expects an array of lambdas representing the tests. The results of the
      # lambdas are converted to true or false based on truthiness. valid_tests?
      # returns true iff all the lambdas return a truthie value.
      def valid_tests?(test_array)
        test_array.each do |test_lambda|
          return false unless !!(test_lambda.call)
        end
        true
      end
    end
  end
end