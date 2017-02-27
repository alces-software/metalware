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
require "test/unit"
require "json"
require_relative "../lib/ruby/lib/alces/stack/templater"

class TC_Templater_Combiner < Test::Unit::TestCase
  def setup
    @basic_hash = {
      nodename: "node_hash_input",
      index: 1,
      bool: true,
      is_nil: nil
    }
    @json_string = '{"nodename":"node_json_input", "index":2}'
    @json_hash = {
      nodename: "node_json_input",
      index: 2
    }
    @nodename = "node_nodename_input"
    @index = 3
    @template_folder = "../etc/templates"
    @example_template = "#{@template_folder}/boot/install.erb"
  end

  def test_no_input
    assert(Alces::Stack::Templater::Combiner.new("","","").get_combined_hash.empty?, "Combined array is not empty")
    assert(Alces::Stack::Templater::Combiner.new(nil,nil,nil,{}).get_combined_hash.empty?, "Combined array is not empty")
    assert(Alces::Stack::Templater::Combiner.new(false,false,false,Hash.new).get_combined_hash.empty?, "Combined array is not empty")
  end

  def test_hash_input
    new_hash = Alces::Stack::Templater::Combiner.new("","", "", @basic_hash).get_combined_hash
    assert_equal(new_hash, @basic_hash, "Did not add hash to combined hash")
    new_hash[:newfeild] = true
    assert_not_equal(new_hash, @basic_hash, "Can not change hash input and combined hash independently")
  end

  def test_json_input
    assert_equal(Alces::Stack::Templater::Combiner.new("","", @json_string).get_combined_hash, @json_hash, "Did not add json to combined hash")
    assert_raise TypeError do Alces::Stack::Templater::Combiner.new("","", @json_hash).get_combined_hash end
    assert_raise JSON::ParserError do Alces::Stack::Templater::Combiner.new("","", @example_template).get_combined_hash end
  end

  def test_nodename_index_input
    new_hash = Alces::Stack::Templater::Combiner.new(@nodename, @index, "").get_combined_hash
    correct_hash = {
      nodename: @nodename,
      index: @index
    }
    assert_equal(correct_hash, new_hash, "Did not add node name or index to combined hash")
  end

  def test_priority_order
    json_hash = Alces::Stack::Templater::Combiner.new("", "", @json_string, @basic_hash).get_combined_hash
    correct_json_hash = {
      nodename: "node_json_input",
      index: 2,
      bool: true,
      is_nil: nil
    }
    assert_equal(correct_json_hash, json_hash, "JSON does not have priority to hash inputs")
  end
end