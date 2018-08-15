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

require 'terminal-table'
require 'overview/table'

module Metalware
  module Commands
    class Overview < CommandHelpers::BaseCommand
      private

      attr_reader :overview_data

      def setup
        unless File.exist? FilePath.overview
          MetalLog.warn 'overview.yaml is missing from the repo'
        end
        @overview_data = Data.load FilePath.overview
      end

      def run
        print_domain_table
        print_groups_table
      end

      def print_domain_table
        fields = overview_data[:domain] || []
        puts Metalware::Overview::Table.new([alces.domain], fields).render
      end

      def print_groups_table
        fields_from_yaml = overview_data[:group] || []
        name_field = { header: 'Group Name', value: '<%= group.name %>' }
        fields = [name_field].concat fields_from_yaml
        puts Metalware::Overview::Table.new(alces.groups, fields).render
      end
    end
  end
end
