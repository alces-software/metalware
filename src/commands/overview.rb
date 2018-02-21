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
      class Domain
        attr_reader :alces

        def initialize(alces, overview_data)
          @alces = alces
        end
      end

      class Group
        attr_reader :display
        attr_reader :alces

        def initialize(alces, overview_data)
          @alces = alces
          raw = { group: [] }.merge(overview_data)
          @display = OpenStruct.new(
            headers: raw[:group].map { |h| h[:header] || '' },
            values: raw[:group].map { |h| h[:value] || '' }
          )
        end

        def table
          Terminal::Table.new(headings: headings, rows: rows)
        end

        private

        def headings
          ['Group'].concat display.headers
        end

        def rows
          alces.groups.map { |group| row(group) }
        end

        def row(group)
          name = '<%= group.name %>'
          ([name].concat display.values).map do |value|
            group.render_erb_template(value)
          end
        end
      end

      private

      attr_reader :overview_data

      def setup
        @overview_data = Data.load FilePath.overview
      end

      def run
        puts Group.new(alces, overview_data).table
      end
    end
  end
end

