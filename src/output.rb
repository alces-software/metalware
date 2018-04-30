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

require 'concurrent'
require 'active_support/core_ext/module/delegation'

require 'utils'

module Metalware
  module Output
    MESSAGES_KEY = :messages

    class << self
      def stderr(*lines)
        # Don't output anything in unit tests to prevent noise.
        warn(*lines) unless $rspec_suppress_output_to_stderr
      end

      def stderr_indented_error_message(text)
        stderr text.gsub(/^/, '>>> ')
      end

      # Methods to output/store for displaying in GUI appropriately depending
      # on if we are in CLI or GUI.

      def cli_only(*lines)
        stderr(*lines) unless in_gui?
      end

      def info(*lines)
        output_to_cli_or_gui(lines, type: :info)
      end

      def success(*lines)
        output_to_cli_or_gui(lines, type: :success)
      end

      def warning(*lines)
        output_to_cli_or_gui(lines, type: :warning)
      end

      def error(*lines)
        output_to_cli_or_gui(lines, type: :danger)
      end

      private

      delegate :in_gui?, to: Utils

      def output_to_cli_or_gui(lines, type:)
        if in_gui?
          store_messages(type, lines)
        else
          stderr(*lines)
        end
      end

      def store_messages(type, lines)
        messages_array = Thread.current.thread_variable_get(MESSAGES_KEY)
        # XXX Better place to initialize this?
        unless messages_array
          messages_array = Concurrent::Array.new
          Thread.current.thread_variable_set(MESSAGES_KEY, messages_array)
        end

        # Note: message type will be used to form class used when displaying
        # message; "text-#{type}" should be a CSS class defined for GUI.
        new_messages = lines.map { |line| Message.new(type, line) }
        messages_array.push(*new_messages)
      end
    end

    Message = Struct.new(:type, :text)
  end
end
