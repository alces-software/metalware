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

module Metalware
  module Output
    class << self
      def stderr(*lines)
        # Don't output anything in unit tests to prevent noise.
        $stderr.puts(*lines) if $PROGRAM_NAME !~ /rspec$/
      end

      def stderr_indented_error_message(text)
        stderr text.gsub(/^/, '>>> ')
      end

      # Methods to output/store for displaying in GUI appropriately depending
      # on if we are in CLI or GUI.

      def warning(*lines)
        if in_gui?
          store_messages(:warning, lines)
        else
          stderr(*lines)
        end
      end

      private

      def in_gui?
        defined? Rails
      end

      def store_messages(type, lines)
        messages_array = Thread.current.thread_variable_get(:messages)
        # XXX Better place to initialize this?
        unless messages_array
          messages_array = Concurrent::Array.new
          Thread.current.thread_variable_set(:messages, messages_array)
        end

        new_messages = lines.map { |line| Message.new(type, line) }
        messages_array.push(*new_messages)
      end
    end

    Message = Struct.new(:type, :text)
  end
end
