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

require 'alces/stack/boot'
require 'capture'
require 'forkprocess'

class TC_Boot_Quick < Test::Unit::TestCase
  def setup
    @default_template_location = "#{ENV['alces_BASE']}/etc/templates/boot/"
    @template = "test.erb"
    @template_str = "Boot template, <%= nodename %>, <%= kernelappendoptions %>"
    @template_str_kickstart =
      "Kickstart template, <%= nodename %>, <%= kernelappendoptions %>" \
      " <%= kickstart %> <% if !permanentboot %>false<% end %>"
    @template_kickstart = "#{ENV['alces_BASE']}/etc/templates/kickstart/test.erb"
    @template_pxe_firstboot_str =
      "PXE template, <%= nodename %>, <%= kernelappendoptions %> " \
      "<%= kickstart %> <% if !permanentboot %>false<% end %> <%= firstboot %>"
    @template_pxe_firstboot = "firstboot.erb"
    File.write("#{@default_template_location}#{@template_pxe_firstboot}",
               @template_pxe_firstboot_str)
    File.write(@template_kickstart, @template_str_kickstart)
    File.write("#{@default_template_location}#{@template}", @template_str)
    File.write("#{ENV['alces_BASE']}/etc/templates/kickstart/#{@template}",
               @template_str)
    @finder = Alces::Stack::Templater::Finder
                .new(@default_template_location, @template)
    @ks_finder = Alces::Stack::Templater::Finder
                .new(@default_template_location, @template_kickstart)
    @input_base = {
      permanentboot: false,
      template: @template,
      kernel_append: "KERNAL_APPEND",
      json: '{"json":"included","kernelappendoptions":"KERNAL_APPEND"}'
    }
    @input_nodename = {}.merge(@input_base)
    @input_nodename[:nodename] = "slave04"
    @input_group = {
      nodename: "SHOULD_BE_OVERRIDDEN",
      group: "slave",
      permanent_boot_flag: false
    }
    @input_group.merge!(@input_base)
    @input_group_kickstart = {}.merge(@input_group)
                               .merge({ kickstart: @template_kickstart })
    @input_group_kickstart[:template] = @template_kickstart
    @input_nodename_kickstart = {}.merge(@input_nodename)
                                  .merge({ kickstart: @template_kickstart })
    @input_nodename_kickstart[:template] = @template_kickstart
    `cp /etc/hosts /etc/hosts.copy`
    `metal hosts -a -g #{@input_group[:group]} -j '{"iptail":"<%= index + 100 %>"}'`
    `mkdir -p /var/lib/tftpboot/pxelinux.cfg/`
    `mkdir -p /var/www/html/ks`
    `rm -rf /var/lib/tftpboot/pxelinux.cfg/*`
    `rm -rf /var/lib/metalware/rendered/ks/*`
    `rm -rf /var/lib/metalware/cache/*`
  end

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
    check_passing(@ks_finder, @input_group_kickstart)
  end

  def test_input_passing_nodename_kickstart
    check_passing(@ks_finder, @input_nodename_kickstart)
  end

  def test_get_save_file
    boot = Alces::Stack::Boot::Run.new(@input_nodename)
    json = @input_nodename[:json]; @input_nodename.delete(:json)
    combiner = Alces::Stack::Templater::Combiner.new(json, @input_nodename)
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

  def test_run_kickstart_single
    boot = Alces::Stack::Boot::Run.new(@input_nodename_kickstart)
    boot.run_kickstart
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
                .new(json, @input_nodename_kickstart).file(@template_kickstart)
    assert_equal(correct.strip,
                 content.chomp,
                 "Did not pass kickstart template correctly")
  end

  def test_run_kickstart_group
    boot = Alces::Stack::Boot::Run.new(@input_group_kickstart)
    boot.run_kickstart
    check_lambda = -> (hash) { 
      assert_equal("/var/lib/metalware/rendered/ks/test.ks.#{hash[:nodename]}",
                   boot.instance_variable_get(:@to_delete)[hash[:index]],
                   "Incorrect save file")
    }
    Alces::Stack::Iterator.run(@input_group_kickstart[:group], check_lambda)
  end

  def test_script_input
    
  end

  def teardown
    `rm #{@default_template_location}#{@template}`
    `rm #{@default_template_location}#{@template_pxe_firstboot}`
    `rm #{ENV['alces_BASE']}/etc/templates/kickstart/#{@template}`
    `rm -f #{@template_kickstart}`
    `mv /etc/hosts.copy /etc/hosts`
  end
end