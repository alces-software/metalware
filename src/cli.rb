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
# See http://stackoverflow.com/questions/837123/adding-a-directory-to-load-path-ruby.
$LOAD_PATH.unshift File.dirname(__FILE__)

require 'rubygems'
require 'bundler/setup'
require 'commander'
require 'config'
require 'colorize'

require 'cli_helper/parser'
require 'data'

module Metalware
  class Cli
    include Commander::Methods

    def run
      program :name, 'metal'
      program :version, '2017.2.1'
      program :description, <<-EOF.squish
        Alces tools for the management and configuration of bare metal machines
      EOF

      suppress_trace_class UserMetalwareError

      CliHelper::Parser.new(self).parse_commands

      run!
    end

    def run!
      ARGV.push '--help' if ARGV.empty?
      super
    end
  end
end
