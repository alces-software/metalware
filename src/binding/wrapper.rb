
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
require 'metal_log'

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
        result = alces_get_value(s, *a, &b)
        updated_callstack = new_callstack(s, *a, &b)
        alces_return_wrapper(result, updated_callstack)
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
          alces_binding.retrieve_value(count, alces_call_stack, s, *a, &b)
        else
          alces_binding.send(s, *a, &b)
        end
      rescue
        callstack = new_callstack(s, *a, &b)
        call_str = call_stack_to_s(callstack)
        raise $!, "#{$!}\nWhen calling: #{call_str}", $!.backtrace
      end

      def alces_return_wrapper(result, updated_callstack)
        last_index = updated_callstack.keys.length - 1
        last_called_method = updated_callstack[last_index][:method]
        if result.nil?
          nil_call_stack = call_stack_to_s(updated_callstack)
          MetalLog.warn('The following call returned nil: ' + nil_call_stack)
          return nil
        elsif [TrueClass, FalseClass].include?(result.class)
          return result
        elsif /to_.*/.match?(last_called_method)
          return result
        else
          Wrapper.new(result, call_stack: updated_callstack)
        end
      end

      def call_stack_to_s(updated_callstack)
        updated_callstack.keys.sort.reduce('') do |msg, idx|
          method_call = updated_callstack[idx]
          msg_period = (msg.empty? ? '' : '.')
          msg_method = method_call[:method].to_s
          args = method_call[:args]
          msg_args = (args.empty? ? '' : "(#{args.join(',')})")
          msg_block = (method_call[:block].nil? ? '' : '{ ... }')
          msg + msg_period + msg_method + msg_args + msg_block
        end
      end

      def new_callstack(s, *a, &b)
        idx = alces_call_stack.keys.length
        alces_call_stack.merge(idx => {
                                 method: s,
                                 args: a,
                                 block: b,
                               })
      end
    end
  end
end
