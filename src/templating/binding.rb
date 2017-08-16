
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

module Metalware
  module Templating
    class Binding
      private_class_method :new

      def self.build(config, node = nil)
        alces_binding = new(metal_config: config, node_name: node)
        BindingWrapper.new(alces_binding).get_binding
      end

      def initialize(metal_config:, node_name:)
        @config = metal_config
        @node = node_name
      end

      def retrieve_value(call_stack, s, *a, &b)
        if call_stack[1] == :alces
          raise NotImplementedError
        else
          retrieve_config_value(call_stack, s)
        end
      end

      def retrieve_config_value(call_stack, s)
        h = loop_through_call_stack(call_stack) || raw_config
        result = h.send(s)
        result.is_a?(IterableRecursiveOpenStruct) ? self : result
      end

      private

      attr_reader :config, :node

      def raw_config
        @raw_config ||= IterableRecursiveOpenStruct.new(template_configuration.raw_config)
      end

      def loop_through_call_stack(call_stack)
        call_stack.keys.sort.reduce(raw_config) do |cur_config, key|
          cur_method = call_stack[key]
          cur_config.send(cur_method[:method])
        end
      end

      def template_configuration
        @template_configuration ||= Configuration.for_node(node, config: config)
      end
    end

    # All methods must be prefaced with 'alces' to prevent them from being
    # accidentally overridden
    class BindingWrapper
      include Blank

      def initialize(binding_obj, call_stack = {})
        @alces_binding = binding_obj
        @alces_call_stack = call_stack
      end

      def method_missing(s, *a, &b)
        alces_return_wrapper(alces_get_value(s, *a, &b), s, a, b)
      end

      def get_binding
        binding
      end

      private

      attr_reader :alces_binding, :alces_call_stack

      def alces_get_value(s, *a, &b)
        if alces_binding.is_a?(Metalware::Templating::Binding)
          alces_binding.retrieve_value(alces_call_stack, s, *a)
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
        BindingWrapper.new(result, new_callstack)
      end
    end
  end
end
