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
require 'command_helpers/node_identifier'
require 'templater'

module Metalware
  module Commands
    class Each < CommandHelpers::BaseCommand
      private

      prepend CommandHelpers::NodeIdentifier

      def setup
        @command = args[1]
      end

      attr_reader :command

      def run
        nodes.each do |node|
          rendered_cmd = node.render_erb_template(command)
          opt = {
            out: $stdout.fileno ? $stdout.fileno : 1,
            err: $stderr.fileno ? $stderr.fileno : 2,
          }
          system(rendered_cmd, opt)
        end
      end
    end
  end
end
