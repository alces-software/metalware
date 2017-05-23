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
require 'logger'

module Metalware
  module Commands
    class MetalLog < Logger
      def warn(*args, &block)
        super(*args, &block)
      end
    end

    class BaseCommand
      def initialize(args, options)
        @metal_log = create_log("metal")
        metal_log.info "metal #{ARGV.join(" ")}"
        setup(args, options)
        run
      rescue Interrupt => e
        handle_interrupt(e)
      rescue Exception => e
        handle_fatal_exception(e)
      end

      private
      attr_reader :metal_log

      def create_log(log_name)
        path = "/var/log/metalware/#{log_name}.log"
        f = File.open(path, "a")
        f.sync = true
        MetalLog.new(f)
      end

      def setup(args, options)
        raise NotImplementedError
      end

      def run
        raise NotImplementedError
      end

      def handle_interrupt(e)
        raise e
      end

      def handle_fatal_exception(e)
        metal_log.fatal e.inspect
        raise e
      end
    end
  end
end
