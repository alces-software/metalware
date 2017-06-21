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

require 'constants'
require 'exceptions'

module Metalware
  module NodeattrInterface
    # XXX Move all other interactions with `nodeattr` to this module.
    class << self
      def nodes_in_group(group)
        stdout = nodeattr("-c #{group}")
        if stdout.empty?
          raise NoGenderGroupError, "Could not find gender group: #{group}"
        end
        stdout.chomp.split(',')
      end

      def groups_for_node(node)
        # If no node passed then it has no groups; without this we would run
        # `nodeattr -l` without args, which would give all groups.
        return [] unless node

        nodeattr("-l #{node}").chomp.split
      rescue SystemCommandError
        raise NodeNotInGendersError, "Could not find node in genders: #{node}"
      end

      private

      def nodeattr(command)
        SystemCommand.run("#{Constants::NODEATTR_COMMAND} #{command}")
      end
    end
  end
end
