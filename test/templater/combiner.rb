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

require "test/unit"
require "json"
require_relative "#{ENV['alces_BASE']}/lib/ruby/lib/alces/stack/templater"

class TC_Templater_Combiner < Test::Unit::TestCase
  def setup
    @default_hash = {hostip: `hostname -i`.chomp}
    @basic_hash = {
      nodename: "node_hash_input",
      index: 1,
      bool: true,
      is_nil: nil,
      hostip: `hostname -i`.chomp
    }
    @json_string = '{"nodename":"node_json_input", "index":2}'
    @nodename = "node_nodename_input"
    @index = 3
    @template_folder = "#{ENV['alces_BASE']}/etc/templates"
    @example_template = "#{@template_folder}/boot/install.erb"
  end

  def test_no_input
    assert_equal(@default_hash, Alces::Stack::Templater::Combiner.new("").combined_hash, "Combined array is not empty")
    assert_equal(@default_hash, Alces::Stack::Templater::Combiner.new(nil,{}).combined_hash, "Combined array is not empty")
    assert_equal(@default_hash, Alces::Stack::Templater::Combiner.new(false,Hash.new).combined_hash, "Combined array is not empty")
  end

  def test_hash_input
    no_hostip = {
      nodename: "node_hash_input",
      index: 1,
      bool: true,
      is_nil: nil
    }
    new_hash = Alces::Stack::Templater::Combiner.new("", no_hostip).combined_hash
    assert_equal(new_hash, @basic_hash, "Did not add hash to combined hash")
    new_hash[:newfeild] = true
    assert_not_equal(new_hash, @basic_hash, "Can not change hash input and combined hash independently")
  end

  def test_json_input
    json_hash = {
      nodename: "node_json_input",
      index: 2,
      hostip: `hostname -i`.chomp
    }
    assert_equal(json_hash, Alces::Stack::Templater::Combiner.new(@json_string).combined_hash, "Did not add json to combined hash")
    assert_raise TypeError do Alces::Stack::Templater::Combiner.new(json_hash).combined_hash end
    assert_raise JSON::ParserError do Alces::Stack::Templater::Combiner.new(@example_template).combined_hash end
  end

  def test_priority_order
    over_default_hash = {
      hostip: "0.0.0.0",
      nodename: "set_by_hash",
      index: 1
    }
    hash_over_default = Alces::Stack::Templater::Combiner.new("",over_default_hash).combined_hash
    assert_equal(over_default_hash, hash_over_default, "Hash did not override default values")
    json_input = '{"nodename":"set_by_json", "index": 2}'
    json_hash = {
      hostip: "0.0.0.0",
      nodename: "set_by_json",
      index: 2
    }
    json_over_hash = Alces::Stack::Templater::Combiner.new(json_input, over_default_hash).combined_hash
    assert_equal(json_hash, json_over_hash, "JSON did not override hash inputs")
  end

  def test_parsed_hash
    # No erb
    assert_equal(@basic_hash, Alces::Stack::Templater::Combiner.new("",@basic_hash).parsed_hash, "Changed hash if no erb is present")
    # Single erb replace
    @basic_hash[:replace_with_hostip] = "<%= hostip %>"
    correct_hash = Hash.new.merge(@basic_hash)
    correct_hash[:replace_with_hostip] = correct_hash[:hostip]
    assert_equal(correct_hash, Alces::Stack::Templater::Combiner.new("",@basic_hash).parsed_hash, "Did not correctly replace a single erb")
    # Chain erb replace
    @basic_hash[:double_replace] = "<%= replace_with_hostip %>"
    @basic_hash[:triple_replace] = "<%= double_replace %>"
    correct_hash[:double_replace] = correct_hash[:hostip]
    correct_hash[:triple_replace] = correct_hash[:hostip]
    assert_equal(correct_hash, Alces::Stack::Templater::Combiner.new("",@basic_hash).parsed_hash, "Did not correctly replace a single erb")
    # Recursion error
    @basic_hash[:recursion_error] = "<%= recursion_error %>a"
    assert_raise Alces::Stack::Templater::Combiner::LoopErbError do Alces::Stack::Templater::Combiner.new("",@basic_hash) end
  end

  def test_file
    assert_raise Alces::Stack::Templater::Combiner::HashInputError do Alces::Stack::Templater::Combiner.new(nil).file("fake.txt", @basic_hash) end
    assert_raise Alces::Stack::Templater::Combiner::HashInputError do Alces::Stack::Templater::Combiner.new(nil).save("fake.txt", "fake.txt", @basic_hash) end
    assert_raise Alces::Stack::Templater::Combiner::HashInputError do Alces::Stack::Templater::Combiner.new(nil).append("fake.txt", "fake.txt", @basic_hash) end
  end
end