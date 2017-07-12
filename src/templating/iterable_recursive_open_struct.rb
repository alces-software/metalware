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
require 'recursive-open-struct'

module Metalware
  module Templating
    class IterableRecursiveOpenStruct < RecursiveOpenStruct
      def each(&block)
        convert_hash_values_to_own_class.each(&block)
      end

      def each=(*args)
        raise IterableRecursiveOpenStructPropertyError,
          "Cannot set property 'each', reserved to use for iteration"
      end

      private

      def convert_hash_values_to_own_class
        to_h.map do |k, v|
          case v
          when Hash
            [k, IterableRecursiveOpenStruct.new(v)]
          else
            [k, v]
          end
        end.to_h
      end
    end
  end
end
