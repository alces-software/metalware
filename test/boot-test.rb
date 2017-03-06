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
    @template_str_kickstart = "#{template_str} <%= kickstart %>"
    @template_kickstart = "/tmp/template.kickstart." << Process.pid.to_s
    File.write(@template_kickstart, @template_str_kickstart)
    File.write("#{@default_template_location}#{@template}", @template_str)
    File.write("#{ENV['alces_BASE']}/etc/templates/kickstart/#{@template}", @template_str)
    @finder = Alces::Stack::Templater::Finder.new(@default_template_location)
    @finder.template = @template
    @input_base = {
      template: @template,
      kernel_append: "KERNAL_APPEND",
      json: '{"json":"included","kernelappendoptions":"KERNAL_APPEND"}'
    }
    @input_nodename = Hash.new.merge(@input_base)
    @input_nodename[:nodename] = "slave04"
    @input_group = {
      nodename: "SHOULD_BE_OVERRIDDEN",
      group: "slave"
    }
    @input_group.merge!(@input_base)
    @input_group_kickstart = Hash.new.merge(@input_group).merge({kickstart:"test"})
    @input_group_kickstart[:template] = @template_kickstart
    @input_nodename_kickstart = Hash.new.merge(@input_nodename).merge({kickstart:"test"})
    @input_nodename_kickstart[:template] = @template_kickstart
    `cp /etc/hosts /etc/hosts.copy`
    `metal hosts -a -g #{@input_group[:group]} -j '{"iptail":"<%= index + 100 %>"}'`
    `mkdir -p /var/lib/tftpboot/pxelinux.cfg/`
    `rm -rf /var/lib/tftpboot/pxelinux.cfg/*`
    `rm -rf /var/lib/metalware/rendered/ks/*`
    `rm -rf /var/lib/metalware/cache/*`
  end

  def check_passing(hash={})
    boot = Alces::Stack::Boot::Run.new(hash)
    assert_equal(@finder.template, boot.instance_variable_get(:@finder).template, "Template incorrect")
    assert_equal(hash[:group], boot.instance_variable_get(:@group), "Group value incorrect")
    assert_equal(hash[:kernel_append], boot.instance_variable_get(:@template_parameters)[:kernelappendoptions], "Kernel append incorrect")
    assert_equal(hash[:nodename].to_s, boot.instance_variable_get(:@template_parameters)[:nodename].to_s, "Nodename incorrect")
    assert_equal(hash[:json], boot.instance_variable_get(:@json), "JSON incorrect")
    assert_equal(hash[:kickstart_template], boot.instance_variable_get(:@kickstart), "Kickstart template incorrect")
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
    combiner = Alces::Stack::Templater::Combiner.new("boot", json, @input_nodename)
    save = boot.get_save_file(combiner)
    assert_equal("/var/lib/tftpboot/pxelinux.cfg/#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}", save, "Incorrect save file name")
  end

  def test_puts_template
    boot = Alces::Stack::Boot::Run.new(@input_nodename)
    @input_nodename[:kernelappendoptions] = "KERNAL_APPEND"
    output = Alces::Stack::Capture.stdout do boot.puts_template(@input_nodename) end
    save = "/var/lib/tftpboot/pxelinux.cfg/#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}"
    string = "BOOT TEMPLATE\nWould save file to: #{save}\n"
    string << Alces::Stack::Templater::Handler.new.replace_erb(@template_str, @input_nodename)
    assert_equal(string.rstrip, output.rstrip, "Did not print the template correctly") 
  end

  def test_save_template
    @input_nodename[:kernelappendoptions] = "KERNAL_APPEND"
    boot = Alces::Stack::Boot::Run.new(@input_nodename)
    boot.save_template(@input_nodename)
    save = "/var/lib/tftpboot/pxelinux.cfg/#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}"
    output = File.read(save)
    string = Alces::Stack::Templater::Handler.new.replace_erb(@template_str, @input_nodename)
    assert_equal(string.rstrip, output.rstrip, "Did not save the template correctly") 
    `rm -f #{save}`
  end

  def test_run_single
    save = "/var/lib/tftpboot/pxelinux.cfg/#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}"
    parent_lambda = -> (fork, pid) {
      assert_equal(false, fork.wait_child_terminated(0.5), "metal boot has exited early")
      output = `cat #{save}`
      @input_nodename[:kernelappendoptions] = "KERNAL_APPEND"
      correct = Alces::Stack::Templater::Handler.new.replace_erb(@template_str, @input_nodename)
      assert_equal(correct, output.chomp, "Did not replace template correctly")
      fork.interrupt_child
      assert_equal(true, fork.wait_child_terminated(2), "metal boot has not finished")
      assert_empty(`ls /var/lib/tftpboot/pxelinux.cfg/`.chomp, "Pxe file have not been deleted")
    }
    child_lambda = lambda { Alces::Stack::Capture.stdout do Alces::Stack::Boot::Run.new(@input_nodename).run! end }
    Alces::Stack::ForkProcess.new(parent_lambda, child_lambda).run
  end

  def test_run_group
    save = "/var/lib/tftpboot/pxelinux.cfg/"
    parent_lambda = -> (fork, pid) {
      assert_equal(false, fork.wait_child_terminated(0.5), "metal boot has exited early")
      check_lambda = -> (hash) {
        ip = `gethostip -x #{hash[:nodename]}`.chomp
        assert_equal(ip, `ls #{save} | grep #{ip}`.chomp, "Could not find pxe file")
      }
      Alces::Stack::Iterator.run(@input_group[:group], check_lambda)
      fork.interrupt_child
      assert_equal(true, fork.wait_child_terminated(2), "metal boot has not finished")
      assert_empty(`ls /var/lib/tftpboot/pxelinux.cfg/`.chomp, "Pxe file have not been deleted")
    }
    child_lambda = lambda { Alces::Stack::Capture.stdout do Alces::Stack::Boot::Run.new(@input_group).run! end }
    Alces::Stack::ForkProcess.new(parent_lambda, child_lambda).run
  end

  def test_run_kickstart_single
    boot = Alces::Stack::Boot::Run.new(@input_nodename_kickstart)
    boot.run_kickstart
    assert_equal("/var/lib/metalware/rendered/ks/test.ks.#{@input_nodename_kickstart[:nodename]}",boot.instance_variable_get(:@to_delete)[0],"Incorrect save file")
    content = File.read("/var/lib/metalware/rendered/ks/test.ks.#{@input_nodename_kickstart[:nodename]}")
    json = @input_nodename_kickstart[:json]
    @input_nodename_kickstart.delete(:json)
    correct = Alces::Stack::Combiner.new("kickstart", json, @input_nodename_kickstart).file(@template_kickstart)
    assert_equal(correct, content, "Did not pass kickstart template correctly")
  end

  def test_run_kickstart_group
    boot = Alces::Stack::Boot::Run.new(@input_group_kickstart)
    boot.run_kickstart
    check_lambda = -> (hash) { 
      assert_equal("/var/lib/metalware/rendered/ks/test.ks.#{hash[:nodename]}",boot.instance_variable_get(:@to_delete)[hash[:index]],"Incorrect save file")
    }
    Alces::Stack::Iterator.run(@input_group_kickstart[:group], check_lambda)
  end

  def test_single_kickstart_command
    save_pxe = "/var/lib/tftpboot/pxelinux.cfg/#{`gethostip -x #{@input_nodename_kickstart[:nodename]}`.chomp}"
    save_kick = "/var/lib/metalware/rendered/ks/test.ks.#{@input_nodename_kickstart[:nodename]}"
    end_kick = "/var/lib/metalware/cache/metalwarebooter.#{@input_nodename_kickstart[:nodename]}"
    parent_lambda = -> (fork, pid) {
      assert_equal(false, fork.wait_child_terminated(0.5), "metal boot has exited early")
      @input_nodename_kickstart[:kernelappendoptions] = "KERNAL_APPEND"
      combiner = Alces::Stack::Templater::Combiner.new("boot", @input_nodename_kickstart[:json], @input_nodename_kickstart)
      output_pxe = `cat #{save_pxe}`.chomp
      correct_pxe = combiner.replace_erb(@template_str, combiner.parsed_hash)
      assert_equal(correct_pxe, output_pxe, "Did not replace template correctly")
      output_kick = `cat #{save_kick}`.chomp
      correct_kick = combiner.file("#{ENV['alces_BASE']}/etc/templates/kickstart/test.erb")
      assert_equal(correct_kick, output_kick, "Did not create correct kickstart file")
      File.write(end_kick, "")
      puts
      puts "This may take 30s"
      assert_equal(true, fork.wait_child_terminated(30), "metal boot has not finished")
      assert_empty(`ls /var/lib/tftpboot/pxelinux.cfg/`.chomp, "Pxe file have not been deleted")
      assert_empty(`ls /var/lib/metalware/cache/`.chomp, "Cache files still exist")
      assert_empty(`ls /var/lib/metalware/rendered/ks/`.chomp, "Kickstart files still exist")
    }
    child_lambda = lambda { Alces::Stack::Capture.stdout do Alces::Stack::Boot::Run.new(@input_nodename_kickstart).run! end }
    Alces::Stack::ForkProcess.new(parent_lambda, child_lambda).run
  end

  def test_group_kickstart_command
    parent_lambda = -> (fork, pid) {
      lambda = -> (hash) {return 1}
      nodes = Alces::Stack::Iterator.run(@input_group_kickstart[:group], lambda)
      assert_equal(false, fork.wait_child_terminated(1), "metal boot has exited early")
      assert_equal(nodes.length, `ls /var/lib/tftpboot/pxelinux.cfg/`.lines.count, "Did not print all pxe files")
      assert_equal(nodes.length, `ls /var/lib/metalware/rendered/ks/`.lines.count, "Did not print all render files")
      puts
      puts "This may take 30s"
      end_lambda = -> (hash) { File.write("/var/lib/metalware/cache/metalwarebooter.#{hash[:nodename]}", "") }
      Alces::Stack::Iterator.run(@input_group_kickstart[:group], end_lambda)
      assert_equal(true, fork.wait_child_terminated(30), "metal boot has not finished")
      assert_empty(`ls /var/lib/tftpboot/pxelinux.cfg/`.chomp, "Pxe file have not been deleted")
      assert_empty(`ls /var/lib/metalware/cache/`.chomp, "Cache files still exist")
      assert_empty(`ls /var/lib/metalware/rendered/ks/`.chomp, "Kickstart files still exist")
    }
    child_lambda = lambda { Alces::Stack::Capture.stdout do Alces::Stack::Boot::Run.new(@input_group_kickstart).run! end }
    Alces::Stack::ForkProcess.new(parent_lambda, child_lambda).run
  end

  def teardown
    `rm #{@default_template_location}#{@template}`
    `rm #{ENV['alces_BASE']}/etc/templates/kickstart/#{@template}`
    `rm -f #{@template_kickstart}`
    `mv /etc/hosts.copy /etc/hosts`
  end
end