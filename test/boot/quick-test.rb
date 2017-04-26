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
$: << "#{ENV['alces_BASE']}/test/boot"

require 'alces/stack/boot'
require 'capture'
require 'forkprocess'
require 'boot-setup'

class TC_Boot_Quick < Test::Unit::TestCase
  include BootTestSetup

  def check_passing(finder, hash={})
    boot = Alces::Stack::Boot::Run.new(hash)
    assert_equal(finder.template,
                 boot.instance_variable_get(:@opt).finder.template,
                 "Template incorrect")
    assert_equal(hash[:group],
                 boot.instance_variable_get(:@opt).group,
                 "Group value incorrect")
    assert_equal(hash[:kernel_append],
                 boot.instance_variable_get(:@opt)
                   .template_parameters[:kernelappendoptions],
                 "Kernel append incorrect")
    assert_equal(hash[:nodename].to_s,
                 boot.instance_variable_get(:@opt)
                   .template_parameters[:nodename].to_s,
                 "Nodename incorrect")
    assert_equal(hash[:json],
                 boot.instance_variable_get(:@opt).json,
                 "JSON incorrect")
    assert_equal(hash[:kickstart],
                 hash[:kickstart] ?
                   boot.instance_variable_get(:@opt).kickstart : nil,
                 "Kickstart template incorrect")
  end

  def test_input_passing_input_nodename
    check_passing(@finder, @input_nodename)
  end

  def test_input_passing_input_group
    check_passing(@finder, @input_group)
  end

  def test_input_passing_group_kickstart
    check_passing(@finder, @input_group_kickstart)
  end

  def test_input_passing_nodename_kickstart
    check_passing(@finder, @input_nodename_kickstart)
  end

  def test_get_save_file
    boot = Alces::Stack::Boot::Run.new(@input_nodename)
    json = @input_nodename[:json]; @input_nodename.delete(:json)
    combiner = Alces::Stack::Templater::Combiner.new(nil, json, @input_nodename)
    save = boot.get_save_file(combiner)
    assert_equal("/var/lib/tftpboot/pxelinux.cfg/" \
                   "#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}",
                 save,
                 "Incorrect save file name")
  end

  def test_puts_template
    boot = Alces::Stack::Boot::Run.new(@input_nodename)
    @input_nodename[:kernelappendoptions] = "KERNAL_APPEND"
    output = Capture.stdout do boot.puts_template(@input_nodename) end
    save = "/var/lib/tftpboot/pxelinux.cfg/" \
           "#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}"
    string = "BOOT TEMPLATE\nWould save file to: #{save}\n"
    string << Alces::Stack::Templater::Handler
                .new.replace_erb(@template_str, @input_nodename)
    assert_equal(string.rstrip,
                 output.rstrip,
                 "Did not print the template correctly")
  end

  def test_save_template
    @input_nodename[:kernelappendoptions] = "KERNAL_APPEND"
    boot = Alces::Stack::Boot::Run.new(@input_nodename)
    boot.save_template(@input_nodename)
    save = "/var/lib/tftpboot/pxelinux.cfg/" \
           "#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}"
    output = File.read(save)
    string = Alces::Stack::Templater::Handler
              .new.replace_erb(@template_str, @input_nodename)
    assert_equal(string.rstrip,
                 output.rstrip,
                 "Did not save the template correctly")
    `rm -f #{save}`
  end

  def test_render_kickstart_single
    boot = Alces::Stack::Boot::Run.new(@input_nodename_kickstart)
    boot.render_kickstart
    assert_equal("/var/lib/metalware/rendered/ks/test.ks." \
                   "#{@input_nodename_kickstart[:nodename]}",
                 boot.instance_variable_get(:@to_delete)[0],
                 "Incorrect save file")
    content = File.read("/var/lib/metalware/rendered/ks/test.ks." \
                          "#{@input_nodename_kickstart[:nodename]}")
    json = @input_nodename_kickstart[:json]
    @input_nodename_kickstart.delete(:json)
    @input_nodename_kickstart[:kickstart] = ""
    correct = Alces::Stack::Templater::Combiner
                .new(nil, json, @input_nodename_kickstart).file(@template_kickstart)
    assert_equal(correct.strip,
                 content.chomp,
                 "Did not pass kickstart template correctly")
  end

  def test_render_kickstart_group
    boot = Alces::Stack::Boot::Run.new(@input_group_kickstart)
    boot.render_kickstart
    check_lambda = -> (hash) {
      assert_equal("/var/lib/metalware/rendered/ks/test.ks.#{hash[:nodename]}",
                   boot.instance_variable_get(:@to_delete)[hash[:index]],
                   "Incorrect save file")
    }
    Alces::Stack::Iterator.run(@input_group_kickstart[:group], check_lambda)
  end

  def test_render_script_nodename
    @input_nodename_script[:permanent_boot] = true
    boot = Alces::Stack::Boot::Run.new(@input_nodename_script)
    boot.render_scripts
    assert_equal("1",
                 `find /var/www/html/scripts -type f | wc -l`.chomp,
                 "To many (or few) script files")
    assert(File.file?("/var/www/html/scripts/slave04/empty"),
           "Script was not placed correctly")
    assert_equal("0",
                 `find /var/lib/metalware/rendered/scripts -type f | wc -l`.chomp,
                 "Rouge scripts in wrong location")
  end

  def test_render_script_group
    boot = Alces::Stack::Boot::Run.new(@input_group_script)
    boot.render_scripts
    num_nodes = Alces::Stack::Iterator.run(@input_group_script[:group],
                                           lambda { |hash| hash[:index] },
                                           {})
                                      .length
    assert_equal((num_nodes * 4).to_s,
                 `find /var/lib/metalware/rendered/scripts -type f | wc -l`.chomp,
                 "To many (or few) script files")
    assert_equal(num_nodes.to_s,
                 `find /var/lib/metalware/rendered/scripts/* -type d | wc -l`.chomp,
                 "To many (or few) script directories")
    assert_equal("0",
                 `find /var/www/html/scripts -type f | wc -l`.chomp,
                 "Rouge scripts in wrong location")
  end
end
