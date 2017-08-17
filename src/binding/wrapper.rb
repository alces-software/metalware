
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

require 'templating/configuration'
require 'templating/iterable_recursive_open_struct'
require 'templating/renderer'
require 'constants'
require 'exceptions'
require 'binding'

module Metalware
  module Binding
    class Wrapper
      include Blank

      def initialize(binding_obj, loop_count = 0, call_stack: {})
        @alces_binding = binding_obj
        @alces_call_stack = call_stack
        @count = loop_count
      end

      def method_missing(s, *a, &b)
        alces_return_wrapper(alces_get_value(s, *a, &b), s, a, b)
      end

      def get_binding
        binding
      end

      def coerce(other)
        [other, alces_binding]
      end

      private

      attr_reader :alces_binding, :alces_call_stack, :count

      def alces_get_value(s, *a, &b)
        if alces_binding.is_a?(Metalware::Binding::Parameter)
          alces_binding.retrieve_value(count, alces_call_stack, s, *a)
        else
          alces_binding.send(s, *a, &b)
        end
      end

      # TODO: make it error if trying to return a nil
      def alces_return_wrapper(result, s, a, b)
        return result if [TrueClass, FalseClass].include?(result.class)
        return result if /to_.*/.match?(s)
        idx = alces_call_stack.keys.length
        new_callstack = alces_call_stack.merge(idx => {
                                                 method: s,
                                                 args: a,
                                                 block: b,
                                               })
        Wrapper.new(result, call_stack: new_callstack)
      end
    end
  end
end
