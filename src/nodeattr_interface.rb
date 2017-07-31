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

require 'constants'
require 'exceptions'
require 'system_command'

module Metalware
  module NodeattrInterface
    class << self
      def nodes_in_primary_group(primary_group)
        nodeattr('--expand')
          .split("\n") # Splits the single string output to 1 line per node
          .map { |node| node.split(/[\s,]/) } # Splits nodename and group string
          .select { |node| node[1] == primary_group } # Match the primary group
          .map { |node| node[0] } # Only return the nodename (instead of groups)
      end

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

      # Returns whether the given file is a valid genders file, along with any
      # validation error.
      def validate_genders_file(genders_path)
        unless File.exist?(genders_path)
          raise FileDoesNotExistError, "File does not exist: #{genders_path}"
        end

        nodeattr("-f #{genders_path} --parse-check", format_error: false)
        [true, '']
      rescue SystemCommandError => e
        [false, e.message]
      end

      private

      def nodeattr(command, format_error: true)
        SystemCommand.run(
          "#{Constants::NODEATTR_COMMAND} #{command}",
          format_error: format_error
        )
      end
    end
  end
end
