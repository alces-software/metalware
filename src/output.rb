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

require 'active_support/core_ext/module/delegation'

require 'utils'

module Metalware
  module Output
    class << self
      def stderr(*lines)
        # Don't output anything in unit tests to prevent noise.
        warn(*lines) unless $rspec_suppress_output_to_stderr
      end

      def stderr_indented_error_message(text)
        stderr text.gsub(/^/, '>>> ')
      end

      def info(*lines)
        stderr(*lines)
      end

      def success(*lines)
        stderr(*lines)
      end

      def warning(*lines)
        stderr(*lines)
      end

      def error(*lines)
        stderr(*lines)
      end
    end
  end
end
