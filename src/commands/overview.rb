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

module Metalware
  module Commands
    class Overview < CommandHelpers::BaseCommand
      private

      OVERVIEW_ERROR = 'Can not construct table from overview.yaml'.freeze

      def setup; end

      def run
        display_fields
        puts Terminal::Table.new(headings: headings, rows: rows)
      end

      def rows
        alces.groups.map { |group| row(group) }
      end

      def headings
        ['Group'] << display_fields.headers
      end

      def row(group)
        [group.name]
      end

      def display_fields
        data = OpenStruct.new(Data.load(FilePath.overview))
        data.headers ||= []
        data.fields ||= []
        unless data.headers.length == data.fields.length
          raise DataError, OVERVIEW_ERROR
        end
        data
      end
    end
  end
end
