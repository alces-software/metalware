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
require 'config'
require 'exceptions'
require 'fileutils'

module Metalware
  class MetalLog < Logger
    class << self
      def method_missing(s, *a, &b)
        metal_log.respond_to?(s) ? metal_log.public_send(s, *a, &b) : super
      end

      attr_writer :config

      def config
        raise UnsetConfigLogError if @config.nil?
        @config
      end

      private

      def metal_log
        @metal_log ||= MetalLog.new("metal")
      end
    end

    def initialize(log_name)
      file = "#{self.class.config.log_path}/#{log_name}.log"
      FileUtils.mkdir_p File.dirname(file)
      f = File.open(file, "a")
      f.sync = true
      super(f)
    end

# POSSIBLE USE TO IMPLEMENT --strict
=begin
      def warn(*args, &block)
        super(*args, &block)
      end
=end
  end
end
