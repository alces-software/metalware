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
require 'templater'
require 'nodes'

module Metalware
  module Commands
    class Each < CommandHelpers::BaseCommand
      private

      def setup(args, options)
        node_identifier = args[0]
        @nodes = Nodes.create(config, node_identifier, options.group)
        @command = args[1]
      end

      def run
        @nodes.template_each do |parameters, _node|
          rendered_cmd = Templater.new(config, parameters)
                                  .render_from_string(@command)
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
