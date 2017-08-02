
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

module Metalware
  # An easily stubbable module to handle certain behaviour which is hard to
  # test directly, so we can just test this receives correct messages.
  module Io
    class << self
      def abort(*args)
        # If we're in a unit test, raise so we can clearly tell an unexpected
        # `abort` occurred, rather than aborting the test suite.
        raise AbortInTestError, *args if $PROGRAM_NAME.match?(/rspec$/)
        Kernel.abort(*args)
      end
    end
  end
end
