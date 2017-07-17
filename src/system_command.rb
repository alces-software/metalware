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

require 'exceptions'

module Metalware
  module SystemCommand
    class << self
      # This is just a slightly more robust version of Kernel.`, so we get an
      # exception that must be handled or be displayed if the command run
      # fails.
      def run(command)
        stdout, stderr, status = Open3.capture3(command)
        if status.exitstatus != 0
          raise SystemCommandError,
                "'#{command}' produced error '#{stderr.strip}'"
        else
          stdout
        end
      end
    end
  end
end
