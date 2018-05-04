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
require 'logger'
require 'exceptions'
require 'fileutils'
require 'output'

module Metalware
  class MetalLog < Logger
    class << self
      # Having these global properties on the MetalLog class is pretty ugly,
      # but for legacy reasons we need to be able to call methods on the
      # MetalLog class directly all over the place, and this is the best way I
      # can see right now to share the values for `strict` and `quiet` set at
      # the top level in BaseCommand with all MetalLog instances without having
      # to completely refactor our use of MetalLog throughout Metalware.
      attr_accessor :strict, :quiet

      def method_missing(s, *a, &b)
        metal_log.respond_to?(s) ? metal_log.public_send(s, *a, &b) : super
      end

      def metal_log
        @metal_log ||= MetalLog.new('metal')
      end
    end

    def initialize(log_name)
      file = "#{FilePath.log}/#{log_name}.log"
      FileUtils.mkdir_p File.dirname(file)
      f = File.open(file, 'a')
      f.sync = true
      super(f)
      self.level = Constants::LOG_SEVERITY
    end

    def warn(msg)
      raise StrictWarningError, msg if strict?
      print_warning(msg)
      super(msg)
    end

    private

    def strict?
      self.class.strict
    end

    def quiet?
      self.class.quiet
    end

    def print_warning(msg)
      return if quiet?
      message_cache[msg] ||= 0
      message_cache[msg] += 1
      return if message_cache[msg] > 1
      Output.warning "warning: #{msg}"
    end

    def message_cache
      @message_cache ||= {}
    end
  end
end
