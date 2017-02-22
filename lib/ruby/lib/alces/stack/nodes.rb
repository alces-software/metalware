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
require 'templater'

module Alces
  module Stack
    class Nodes
      def initialize(gender, &block)
        @gender = gender
        raise "Could not find gender group" if `nodeattr -c #{@gender}`.empty?
        yield self if !block.nil?
      end

      def each(&block)
        `nodeattr -c #{@gender}`.split(',').each(&block)
      end

      def each_with_index(&block)
        `nodeattr -c #{@gender}`.split(',').each_with_index(&block)
      end
    end

    class Iterator
      def initialize(gender, lambda, json)
        if !gender
          lambda.call(json)
        else
          iterate(gender, lambda, json)
        end
      end

      def iterate(gender, lambda, json)
        json_hash = Alces::Stack::Templater::JSON_Templater.parse(json)
        Nodes.new(gender).each_with_index do |nodename, index|
          json_hash[:nodename] = nodename
          json_hash[:index] = index
          lambda.call(json_hash.to_json)
        end
      end
    end
  end
end