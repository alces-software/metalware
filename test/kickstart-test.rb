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
require_relative "#{ENV['alces_BASE']}/test/helper/base-test-require.rb" 

require "alces/stack/kickstart"
require "alces/stack/templater"
require "alces/stack/iterator"
require "capture"

`rm /var/lib/metalware/rendered/ks/* -rf`
class TC_Kickstart < Test::Unit::TestCase
  def setup
    @template = "/tmp/template." << Process.pid.to_s
    @template_str = "<%= nodename %> <%= index %>"
    File.write(@template, @template_str)
    @hash = {
      group: "group",
      nodename: "nodename",
      json: '{"json":"included", "index":0}',
      dry_run_flag: true,
      ran_from_boot: false,
      save_append: "append"
    }
    @finder = Alces::Stack::Templater::Finder.new("#{ENV['alces_BASE']}/etc/templates/kickstart/", @template)
  end

  def options_checker(ks_o, template, hash={})
    finder= Alces::Stack::Templater::Finder.new("#{ENV['alces_BASE']}/etc/templates/kickstart/", template)
    assert_equal(finder.template, ks_o.instance_variable_get(:@finder).template, "Did not set template")
    assert_equal(hash[:group], ks_o.instance_variable_get(:@group), "Incorrect group")
    assert_equal(hash[:json], ks_o.instance_variable_get(:@json), "Incorrect json")
    assert_equal(hash[:save_append], ks_o.instance_variable_get(:@save_append), "Incorrect save_append")
    assert_equal(hash[:dry_run_flag], ks_o.instance_variable_get(:@dry_run_flag), "Incorrect dry_run_flag")
    assert_equal(hash[:ran_from_boot], ks_o.instance_variable_get(:@ran_from_boot), "Incorrect ran_from_boot")
    assert_equal(hash[:nodename], ks_o.instance_variable_get(:@template_parameters)[:nodename], "Incorrect nodename")
  end

  def test_input_parsing
    ks = Alces::Stack::Kickstart::Run.new(@template)
    options_checker(ks, @template)
    ks = Alces::Stack::Kickstart::Run.new(@template, @hash)
    options_checker(ks, @template, @hash)
  end

  def check_put_template(hash)
    # Manually determines correct file save location
    ks = Alces::Stack::Kickstart::Run.new(@finder.template, hash)
    template_parameters = ks.instance_variable_get(:@template_parameters)
    combiner = Alces::Stack::Templater::Combiner.new(ks.instance_variable_get(:@json), template_parameters)
    
    expected_str = "KICKSTART TEMPLATE\nHash:" << combiner.parsed_hash.to_s
    expected_str << "\nSave: /var/lib/metalware/rendered/ks/" << @finder.filename_diff_ext("ks")
    if !hash[:save_append].to_s.empty? then expected_str << "." << hash[:save_append].to_s end
    if !hash[:group].to_s.empty? then expected_str << "." << hash[:nodename].to_s end
    expected_str << "\nTemplate:\n" << combiner.file(@finder.template) << "\n"
    
    stdout = Capture.stdout do ks.puts_template(template_parameters) end
    assert_equal(expected_str, stdout, "Puts template did not print the correct text")
  end

  def test_put_template
    check_put_template({})
    check_put_template(@hash)
    @hash[:group] = ""
    check_put_template(@hash)
  end

  def check_save_template(hash)
    # Uses inbuilt function to determine save location
    ks = Alces::Stack::Kickstart::Run.new(@finder.template, hash)
    json = hash[:json]
    hash.delete(:json)
    template_parameters = ks.instance_variable_get(:@template_parameters)
    ks.save_template(template_parameters)
    finder_save = nil
    assert_nothing_raised do finder_save = Alces::Stack::Templater::Finder.new("/var/lib/metalware/rendered/ks/", ks.get_save_file(template_parameters[:nodename])) end
    exp_parsed_temp = Alces::Stack::Templater::Combiner.new(json, hash).file(@finder.template) << "\n"
    assert_equal(exp_parsed_temp, File.read(finder_save.template))
  end

  def test_save_template
    check_save_template({})
    check_save_template(@hash)
  end

  def test_complete_run
    bash = File.read("/etc/profile.d/alces-metalware.sh")
    `#{bash}\n metal kickstart`
    assert_nothing_raised do Alces::Stack::Templater::Finder.new("/var/lib/metalware/rendered/ks/", "compute.ks") end
    `#{bash}\n metal kickstart -n random`
    assert_nothing_raised do Alces::Stack::Templater::Finder.new("/var/lib/metalware/rendered/ks/", "compute.ks") end
    `#{bash}\n metal kickstart -n random --save-append appended`
    assert_nothing_raised do Alces::Stack::Templater::Finder.new("/var/lib/metalware/rendered/ks/", "compute.ks.appended") end
    `#{bash}\n metal kickstart -g slave --save-append appended`
    lambda_proc = -> (hash) {assert_nothing_raised do Alces::Stack::Templater::Finder.new("/var/lib/metalware/rendered/ks/" ,"compute.ks.appended.#{hash[:nodename]}") end}
    Alces::Stack::Iterator.run("slave", lambda_proc)
  end

  def teardown
    File.delete(@template) if File.exist?(@template)
    `rm /var/lib/metalware/rendered/ks/* -rf`
  end
end
