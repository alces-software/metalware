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
require 'alces/stack/templater'
require 'alces/stack/nodes'

module Alces
  module Stack
    class Iterator
      def initialize(gender, lambda, json)
        if !gender
          return lambda.call(json)
        else
          return iterate(gender, lambda, json)
        end
      end

      def iterate(gender, lambda, json)
        json_hash = Alces::Stack::Templater::JSON_Templater.parse(json)
        output = Array.new
        Nodes.new(gender).each_with_index do |nodename, index|
          json_hash[:nodename] = nodename
          json_hash[:index] = index
          output << lambda.call(json_hash.to_json)
        end
        return output
      end
    end
  end
end