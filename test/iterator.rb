#!/usr/bin/env ruby
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
raise "alces_BASE has not been set in ENV" if !ENV['alces_BASE']
$LOAD_PATH << "#{ENV['alces_BASE']}/lib/ruby/lib/".gsub!("//","/")

require "test/unit"
require "alces/stack/iterator"

class TC_Iterator < Test::Unit::TestCase
  def setup
    @lambda = ->(options) {
      return options
    }
    @hash = {
      nodename: "nodename default",
      index: -1,
      other: "other"
    }
    #Generates the node list
    @group = "nodes"
    @group_array = `nodeattr -c #{@group}`.gsub!("\n","").split(",")
  end

  def test_invalid_inputs
    assert_raise ArgumentError do Alces::Stack::Iterator.run() end
    assert_raise Alces::Stack::Iterator::GenderError do Alces::Stack::Iterator.run("NotFound", @lambda) end
  end

  def test_single_node_input
    assert_equal(Hash.new, Alces::Stack::Iterator.run("", @lambda), "Incorrect output for empty hash input on single node")
    assert_equal(Hash.new, Alces::Stack::Iterator.run(false, @lambda), "Incorrect output for empty hash input on single node")
    assert_equal(Hash.new, Alces::Stack::Iterator.run(nil, @lambda), "Incorrect output for empty hash input on single node")
    assert_equal(@hash, Alces::Stack::Iterator.run("", @lambda, @hash), "Incorrect output for hash input on single node")
  end

  def test_group_node_input
    result = Alces::Stack::Iterator.run(@group, @lambda)
    @group_array.each_with_index do |nodename, index|
      test_hash = {
        nodename: nodename,
        index: index
      }
      assert_equal(test_hash, result[index], "Incorrect returned hash for group with no hash input")
    end
    result = Alces::Stack::Iterator.run(@group, @lambda, @hash)
    @group_array.each_with_index do |nodename, index|
      @hash[:nodename] = nodename
      @hash[:index] = index
      assert_equal(@hash, result[index], "Incorrect returned hash for group with hash input")
    end
  end
end