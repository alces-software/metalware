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

require 'alces/stack/boot'
require 'alces/stack/capture'
require 'alces/stack/forkprocess'

class TC_Boot < Test::Unit::TestCase
  def setup
    @default_template_location = "#{ENV['alces_BASE']}/etc/templates/boot/"
    @template = "test.erb"
    @template_str = "Boot template, <%= nodename %>, <%= kernelappendoptions %>"
    File.write("#{@default_template_location}#{@template}", @template_str)
    @finder = Alces::Stack::Templater::Finder.new(@default_template_location)
    @finder.template = @template
    @input_base = {
      template: @template,
      kernel_append: "KERNAL_APPEND",
      json: '{"json":"included"}'
    }
    @input_nodename = Hash.new.merge(@input_base)
    @input_nodename[:nodename] = "slave04"
    @input_group = {
      nodename: "SHOULD_BE_OVERRIDDEN",
      group: "slave"
    }
    @input_group.merge!(@input_base)
    @input_group_kickstart = Hash.new.merge(@input_group).merge({kickstart:"compute"})
    @input_nodename_kickstart = Hash.new.merge(@input_nodename).merge({kickstart:"compute"})
    `cp /etc/hosts /etc/hosts.copy`
    `metal hosts -a -g #{@input_group[:group]} -j '{"iptail":"<%= index + 100 %>"}'`
    `mkdir -p /var/lib/tftpboot/pxelinux.cfg/`
  end

  def check_passing(hash={})
    boot = Alces::Stack::Boot::Run.new(hash)
    assert_equal(@finder.template, boot.instance_variable_get(:@finder).template, "Template incorrect")
    assert_equal(hash[:group], boot.instance_variable_get(:@group), "Group value incorrect")
    assert_equal(hash[:kernel_append], boot.instance_variable_get(:@template_parameters)[:kernelappendoptions], "Kernel append incorrect")
    assert_equal(hash[:nodename].to_s, boot.instance_variable_get(:@template_parameters)[:nodename].to_s, "Nodename incorrect")
    assert_equal(hash[:json], boot.instance_variable_get(:@json), "JSON incorrect")
    assert_equal(hash[:kickstart], boot.instance_variable_get(:@kickstart), "Kickstart template incorrect")
  end

  def test_input_passing
    check_passing(@input_nodename)
    check_passing(@input_group)
    check_passing(@input_group_kickstart)
    check_passing(@input_nodename_kickstart)
  end

  def test_get_save_file
    boot = Alces::Stack::Boot::Run.new(@input_nodename)
    json = @input_nodename[:json]; @input_nodename.delete(:json)
    combiner = Alces::Stack::Templater::Combiner.new(json, @input_nodename)
    save = boot.get_save_file(combiner)
    assert_equal("/var/lib/tftpboot/pxelinux.cfg/#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}", save, "Incorrect save file name")
  end

  def test_puts_template
    boot = Alces::Stack::Boot::Run.new(@input_nodename)
    output = Alces::Stack::Capture.stdout do boot.puts_template(@input_nodename) end
    save = "/var/lib/tftpboot/pxelinux.cfg/#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}"
    string = "BOOT TEMPLATE\nWould save file to: #{save}\n"
    string << Alces::Stack::Templater::Handler.new.replace_erb(@template_str, @input_nodename)
    assert_equal(string.rstrip, output.rstrip, "Did not print the template correctly") 
  end

  def test_save_template
    boot = Alces::Stack::Boot::Run.new(@input_nodename)
    boot.save_template(@input_nodename)
    save = "/var/lib/tftpboot/pxelinux.cfg/#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}"
    output = File.read(save)
    string = Alces::Stack::Templater::Handler.new.replace_erb(@template_str, @input_nodename)
    assert_equal(string.rstrip, output.rstrip, "Did not save the template correctly") 
    `rm -f #{save}`
  end

  def test_cl_dry_run
    puts 
    Alces::Stack::ForkProcess.test
    #Alces::Stack::ForkProcess.new(parent_lambda, child_lambda).run
  end

  def teardown
    `rm #{@default_template_location}#{@template}`
    `mv /etc/hosts.copy /etc/hosts`
  end
end