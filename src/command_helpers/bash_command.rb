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

require 'command_helpers/base_command'
require 'metal_log'
require 'config'
require 'constants'

module Metalware
  module CommandHelpers
    class BashCommand < BaseCommand
      private

      def setup(_args, _options)
        @command = ARGV[0]
        @cli_input = ARGV[1..(ARGV.length - 1)]
      end

      def run
        script = File.join(Constants::METALWARE_INSTALL_PATH,
                           'libexec',
                           @command.to_s)
        MetalLog.info "Running: #{script}"
        MetalLog.info "Inputs: #{@cli_input}"
        exec(script, *@cli_input)
      end
    end
  end
end
