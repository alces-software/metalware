
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

module Metalware
  module Templating
    class Binding
      private_class_method :new

      def self.build(config, node = nil)
        alces_binding = new(config: config, node_name: node)
        BindingWrapper.new(alces_binding).get_binding
      end

      def initialize(config:, node_name:)
        @metalware_config = config
        @node = node_name
      end

      def retrieve_value(loop_count, call_stack, s, *a, &b)
        if call_stack[1] == :alces
          raise NotImplementedError
        else
          retrieve_config_value(loop_count, call_stack, s)
        end
      end

      def retrieve_config_value(loop_count, call_stack, s)
        config_struct = loop_through_call_stack(call_stack)
        result = config_struct.send(s)
        if result.is_a?(IterableRecursiveOpenStruct)
          self
        else
          result = replace_erb(result, loop_count) if result.is_a?(String)
          config_struct.send(:"#{s}=", result)
          config_struct.send(s)
        end
      end

      private

      attr_reader :metalware_config, :node, :cache_config

      def config
        @config ||= IterableRecursiveOpenStruct.new(template_configuration.raw_config)
      end

      def loop_through_call_stack(call_stack)
        call_stack.keys.sort.reduce(config) do |cur_config, key|
          cur_method = call_stack[key]
          cur_config.send(cur_method[:method])
        end
      end

      def template_configuration
        @template_configuration ||= Configuration.for_node(node, config: metalware_config)
      end

      def replace_erb(result, loop_count)
        Renderer.replace_erb(result, new_binding(loop_count))
      end

      def new_binding(loop_count)
        raise LoopErbError if loop_count > Constants::MAXIMUM_RECURSIVE_CONFIG_DEPTH
        BindingWrapper.new(self, loop_count + 1).get_binding
      end
    end

    # All methods must be prefaced with 'alces' to prevent them from being
    # accidentally overridden
    class BindingWrapper
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
        if alces_binding.is_a?(Metalware::Templating::Binding)
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
        BindingWrapper.new(result, call_stack: new_callstack)
      end
    end
  end
end
