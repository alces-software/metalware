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
      def nodes_in_group(group)
        nodes_to_genders.select do |_node, genders|
          genders.first == group
        end.keys
      end

      def nodes_in_gender(gender)
        stdout = nodeattr("-c #{gender}")
        if stdout.empty?
          raise NoGenderGroupError, "Could not find gender: #{gender}"
        end
        stdout.chomp.split(',')
      end

      # The hostlist notation is: nodeA[01-10],nodeB
      def hostlist_nodes_in_gender(gender)
        nodeattr("-q #{gender}").chomp
      end

      def genders_for_node(node)
        # If no node passed then it has no groups; without this we would run
        # `nodeattr -l` without args, which would give all groups.
        return [] unless node

        nodeattr("-l #{node}").chomp.split
      rescue SystemCommandError
        raise NodeNotInGendersError, "Could not find node in genders: #{node}"
      end

      def all_nodes
        nodeattr('--expand')
          .split("\n")
          .map { |node_details| node_details.split[0] }
      end

      # Returns whether the given file is a valid genders file, along with any
      # validation error.
      def validate_genders_file(genders_path)
        unless File.exist?(genders_path)
          raise FileDoesNotExistError, "File does not exist: #{genders_path}"
        end

        nodeattr("-f #{genders_path} --parse-check", format_error: false)
        true
      end

      def nodeattr(command, format_error: true, mock_nodeattr: nil)
        mock_nodeattr ||= Constants::NODEATTR_COMMAND
        SystemCommand.run(
          "#{mock_nodeattr} #{command}",
          format_error: format_error
        )
      end

      private

      def nodes_to_genders
        nodeattr('--expand')
          .split("\n")
          .map(&:split)
          .to_h
          .transform_values { |groups| groups.split(',') }
      end
    end
  end
end
