
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
    class Parameter
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
        if result.is_a?(Templating::IterableRecursiveOpenStruct)
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
        @config ||= Templating::IterableRecursiveOpenStruct.new(template_configuration.raw_config)
      end

      def loop_through_call_stack(call_stack)
        call_stack.keys.sort.reduce(config) do |cur_config, key|
          cur_method = call_stack[key]
          cur_config.send(cur_method[:method])
        end
      end

      def template_configuration
        @template_configuration ||= Templating::Configuration.for_node(node, config: metalware_config)
      end

      def replace_erb(result, loop_count)
        Templating::Renderer.replace_erb(result, new_binding(loop_count))
      end

      def new_binding(loop_count)
        raise LoopErbError if loop_count > Constants::MAXIMUM_RECURSIVE_CONFIG_DEPTH
        Wrapper.new(self, loop_count + 1).get_binding
      end
    end
  end
end
