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
ENV['BUNDLE_GEMFILE'] ||= "#{ENV['alces_BASE']}/lib/ruby/Gemfile"
$: << "#{ENV['alces_BASE']}/lib/ruby/lib"

require 'rubygems'
require 'bundler/setup'
Bundler.setup(:default)
require 'test/unit'

require "json"
require "alces/stack/templater"
require "alces/stack/capture"

class TC_Templater_Combiner < Test::Unit::TestCase
  def setup
    @default_hash = {
      hostip: `hostname -i`.chomp,
      index: 0
    }
    @basic_hash = {
      nodename: "node_hash_input",
      index: 1,
      bool: true,
      is_nil: nil,
      hostip: `hostname -i`.chomp
    }
    @json_string = '{"hostip":"0.0.0.0"}'
    @nodename = "node_nodename_input"
    @index = 3
    @template_folder = "#{ENV['alces_BASE']}/etc/templates"
    @example_template = "#{@template_folder}/boot/install.erb"
    `mv #{ENV['alces_BASE']}/etc/config #{ENV['alces_BASE']}/etc/config.copy 2>&1`
    `cp -r #{ENV['alces_BASE']}/test/config-test #{ENV['alces_BASE']}/etc/config`
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
      hostip: "0.0.0.0",
      index: 0
    }
    assert_equal(json_hash, Alces::Stack::Templater::Combiner.new(@json_string).combined_hash, "Did not add json to combined hash")
    assert_raise TypeError do Alces::Stack::Templater::Combiner.new(json_hash).combined_hash end
    assert_raise JSON::ParserError do Alces::Stack::Templater::Combiner.new(@example_template).combined_hash end
  end

  def test_priority_order
    over_default_hash = {
      hostip: "0.0.0.0",
      nodename: "set_by_hash",
      index: 0
    }
    hash_over_default = Alces::Stack::Templater::Combiner.new("",over_default_hash).combined_hash
    assert_equal(over_default_hash, hash_over_default, "Hash did not override default values")
    json_input = '{"hostip": "1.1.1.1"}'
    json_hash = {
      hostip: "1.1.1.1",
      nodename: "set_by_hash",
      index: 0
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

  def test_load_yaml_hash_no_nodename
    assert_equal(@default_hash, Alces::Stack::Templater::Combiner.new("").parsed_hash, "Yaml hash not empty")
  end

  def test_yaml_all_cluster_config
    hash = {
      nodename: "slave01",
      config: "cluster",
      iptail: 1,
      q3: 6,
      index: 0
    }
    hash.merge!(@default_hash)
    assert_equal(hash, Alces::Stack::Templater::Combiner.new("",nodename:"slave01").parsed_hash, "Has not passed yaml")
  end

  def test_yaml_all_cluster_config_slave04
    hash = {
      nodename: "slave04",
      config: "slave04",
      iptail: 1,
      q3: 7,
      index: 0
    }
    hash.merge!(@default_hash)
    assert_equal(hash, Alces::Stack::Templater::Combiner.new("",nodename:"slave04").parsed_hash, "Yaml pass or load order error")
  end

  def test_json_overide_yaml
    hash = {
      nodename: "slave04",
      config: "json",
      iptail: 1,
      q3: 0,
      index: 0
    }
    hash.merge!(@default_hash)
    json = '{
      "config":"json",
      "q3":0
    }'
    assert_equal(hash, Alces::Stack::Templater::Combiner.new(json,nodename:"slave04").parsed_hash, "Yaml has not overridden JSON")
  end

  def test_override_nodename_index_error
    json = '{"nodename":1}'
    assert_raise(Alces::Stack::Templater::Combiner::HashOverrideError) do Alces::Stack::Templater::Combiner.new(json) end
    json = '{"index":1}'
    assert_raise(Alces::Stack::Templater::Combiner::HashOverrideError) do Alces::Stack::Templater::Combiner.new(json) end
  end

  def teardown
    `rm -rf #{ENV['alces_BASE']}/etc/config 2>&1`
    `mv #{ENV['alces_BASE']}/etc/config.copy #{ENV['alces_BASE']}/etc/config 2>&1`
  end
end