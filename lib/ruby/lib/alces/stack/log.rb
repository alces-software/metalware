#==============================================================================
# Copyright (C) 2007-2015 Stephen F. Norledge and Alces Software Ltd.
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
require 'logger'

module Alces
  module Stack
    class Log
      class << self
        def stderr
          @log_stderr ||= Logger.new($stderr)
        end

        def logger
          @log ||= new_log
        end

        def new_log
          f = File.open('/var/log/metalware/metal.log', "a")
          f.sync = true
          Logger.new(f)
        end

        def create_log(file)
          f = File.open(file, "a")
          f.sync = true
          Logger.new(f)
        end

        def method_missing(s, *a)
          logger.respond_to?(s) ? logger.public_send(s, *a) : super
        end
      end
    end
  end
end