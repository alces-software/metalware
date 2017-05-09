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

module Alces
  module Stack
    module Iterator
      class << self
        def run(gender, lambda_proc, options={})
          if !gender or gender.to_s.empty?
            return lambda_proc.call(options)
          else
            return iterate(gender, lambda_proc, options)
          end
        end

        def iterate(gender, lambda_proc, options={})
          output = Array.new
          Nodes.new(gender).each_with_index do |nodename, index|
            options[:nodename] = nodename
            options[:index] = index
            output << Marshal.load(Marshal.dump(lambda_proc.call(options)))
          end
          return output
        end
      end

      class Nodes
        def initialize(gender, &block)
          @gender = gender
          yield self if !block.nil?
        end

        def each(&block)
          run_nodeattr.each(&block)
        end

        def each_with_index(&block)
          run_nodeattr.each_with_index(&block)
        end

        def run_nodeattr
          n = `nodeattr -c #{@gender}`
          raise GenderError if n.empty?
          return n.gsub("\n","").split(',')
        end
      end

      class GenderError < StandardError
        def initialize(msg="Could not find gender group")
          super
        end
      end
    end
  end
end