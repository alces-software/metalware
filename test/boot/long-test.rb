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

class TC_Boot_Long < Test::Unit::TestCase
  include BootTestSetup
  
  def test_single_kickstart_command
    save_pxe = "/var/lib/tftpboot/pxelinux.cfg/" \
               "#{`gethostip -x #{@input_nodename_kickstart[:nodename]}`.chomp}"
    save_kick = "/var/lib/metalware/rendered/ks/test.ks." \
                "#{@input_nodename_kickstart[:nodename]}"
    end_kick = "/var/lib/metalware/cache/metalwarebooter." \
               "#{@input_nodename_kickstart[:nodename]}"
    
    parent_lambda = -> (fork, pid) {
      assert_equal(false,
                   fork.wait_child_terminated(0.5),
                   "metal boot has exited early")
      @input_nodename_kickstart[:kernelappendoptions] = "KERNAL_APPEND"
      hash_temp = Hash.new.merge(@input_nodename_kickstart)
      hash_temp[:kickstart] = "test.ks.slave04"
      output_pxe = `cat #{save_pxe}`.chomp
      combiner = Alces::Stack::Templater::Combiner
                   .new("", @input_nodename_kickstart[:json], hash_temp)
      correct_pxe = combiner.file("#{@default_template_location}/#{@template}")
      assert_equal(correct_pxe, output_pxe, "Did not replace template correctly")
      output_kick = `cat #{save_kick}`.chomp
      correct_kick =
        combiner.file("#{ENV['alces_REPO']}/templates/kickstart/test.erb")
      assert_equal(correct_kick,
                   output_kick, 
                   "Did not create correct kickstart file")
      puts
      puts "Tester: This may take 30s"
      sleep 5
      File.write(end_kick, "")
      exited = fork.wait_child_terminated(20)
      assert_empty(`ls /var/lib/tftpboot/pxelinux.cfg/`.chomp,
                   "Pxe file have not been deleted")
      assert_empty(`ls /var/lib/metalware/cache/`.chomp,
                   "Cache files still exist")
      assert_empty(`ls /var/lib/metalware/rendered/ks/`.chomp,
                   "Kickstart files still exist")
      assert_equal(true,
                   exited,
                   "metal boot -k cleaned up files correctly but didn't exit")
    }

    child_lambda = lambda {
      Capture.stdout {
        Alces::Stack::Boot::Run.new(@input_nodename_kickstart).run!
      }
    }

    ForkProcess.new(parent_lambda, child_lambda).run
  end

  def test_group_kickstart_command
    parent_lambda = -> (fork, pid) {
      lambda = -> (hash) {return 1}
      nodes = Alces::Stack::Iterator.run(@input_group_kickstart[:group], lambda)
      assert_equal(false,
                   fork.wait_child_terminated(2),
                   "metal boot has exited early")
      assert_equal(nodes.length,
                   `ls /var/lib/tftpboot/pxelinux.cfg/`.lines.count,
                   "Did not print all pxe files")
      assert_equal(nodes.length,
                   `ls /var/lib/metalware/rendered/ks/`.lines.count,
                   "Did not print all render files")
      puts
      puts "Tester: This may take 30s"
      sleep 5
      end_lambda = -> (hash) {
        File.write("/var/lib/metalware/cache/metalwarebooter.#{hash[:nodename]}", "") 
      }
      Alces::Stack::Iterator.run(@input_group_kickstart[:group], end_lambda)
      exited = fork.wait_child_terminated(20)
      assert_empty(`ls /var/lib/tftpboot/pxelinux.cfg/`.chomp,
                   "Pxe file have not been deleted")
      assert_empty(`ls /var/lib/metalware/cache/`.chomp,
                   "Cache files still exist")
      assert_empty(`ls /var/lib/metalware/rendered/ks/`.chomp,
                   "Kickstart files still exist")
      assert_equal(true,
                   exited,
                   "metal boot -k cleaned up files correctly but didn't exit")
    }

    child_lambda = lambda {
      Capture.stdout {
        Alces::Stack::Boot::Run.new(@input_group_kickstart).run!
      }
    }
    
    ForkProcess.new(parent_lambda, child_lambda).run
  end

  def test_permanent_boot
    @input_nodename_kickstart[:kernelappendoptions] = "KERNAL_APPEND"
    @input_nodename_kickstart[:template] = @template_pxe_firstboot
    @input_nodename_kickstart[:permanent_boot] = true
    save_pxe = "/var/lib/tftpboot/pxelinux.cfg/" \
               "#{`gethostip -x #{@input_nodename_kickstart[:nodename]}`.chomp}"
    save_kick = "/var/www/html/ks/test.ks.#{@input_nodename_kickstart[:nodename]}"
    end_kick = "/var/lib/metalware/cache/metalwarebooter." \
               "#{@input_nodename_kickstart[:nodename]}"
    
    parent_lambda = -> (fork, pid) {
      assert_equal(false, 
                   fork.wait_child_terminated(0.5),
                   "metal boot has exited early")
      hash_temp = {}.merge(@input_nodename_kickstart)
      hash_temp[:kickstart] = "test.ks.#{@input_nodename_kickstart[:nodename]}"
      hash_temp[:firstboot] = true
      combiner = Alces::Stack::Templater::Combiner
                   .new("", @input_nodename_kickstart[:json], hash_temp)
      output_pxe = `cat #{save_pxe}`.chomp
      correct_pxe = combiner.replace_erb(@template_pxe_firstboot_str,
                                         combiner.parsed_hash)
      assert_equal(correct_pxe,
                   output_pxe,
                   "Firstboot pxe file has not been rendered correctly")
      puts
      puts "Tester: This may take 30s"
      sleep 5
      File.write(end_kick, "")
      exited = fork.wait_child_terminated(20)
      assert_empty(`ls /var/lib/metalware/cache/`.chomp,
                   "Cache files still exist")
      assert(File.file?(save_pxe), "Pxe file has been deleted")
      assert(File.file?(save_kick), "Kickstart file has been deleted")
      hash_temp[:firstboot] = false
      combiner = Alces::Stack::Templater::Combiner
                   .new("", @input_nodename_kickstart[:json], hash_temp)
      output_pxe = `cat #{save_pxe}`.chomp
      correct_pxe = combiner.replace_erb(@template_pxe_firstboot_str,
                                         combiner.parsed_hash)
      assert_equal(correct_pxe,
                   output_pxe,
                   "Secondboot pxe file has not been rendered correctly")
      assert_equal(true,
                   exited,
                   "metal boot -k cleaned up files correctly but didn't exit")
    }

    child_lambda = lambda {
      Capture.stdout do
        Alces::Stack::Boot::Run.new(@input_nodename_kickstart).run!
      end
    }

    ForkProcess.new(parent_lambda, child_lambda).run
  end

  def test_run_single
    save = "/var/lib/tftpboot/pxelinux.cfg/" \
           "#{`gethostip -x #{@input_nodename[:nodename]}`.chomp}"
    puts "\nTester: This may take 5s"
    parent_lambda = -> (fork, pid) {
      assert_equal(false,
                   fork.wait_child_terminated(1),
                   "metal boot has exited early")
      output = `cat #{save}`
      @input_nodename[:kernelappendoptions] = "KERNAL_APPEND"
      correct = Alces::Stack::Templater::Handler
                  .new.replace_erb(@template_str, @input_nodename)
      assert_equal(correct, output.chomp, "Did not replace template correctly")
      fork.interrupt_child
      assert_equal(true,
                   fork.wait_child_terminated(4),
                   "metal boot has not finished")
      assert_empty(`ls /var/lib/tftpboot/pxelinux.cfg/`.chomp,
                   "Pxe file have not been deleted")
    }

    child_lambda = lambda {
      Capture.stdout {
        Alces::Stack::Boot::Run.new(@input_nodename).run! 
        } 
      }
    
    ForkProcess.new(parent_lambda, child_lambda).run
  end

  def test_run_group
    save = "/var/lib/tftpboot/pxelinux.cfg/"
    puts "\nTester: This may take 5s"
    parent_lambda = -> (fork, pid) {
      assert_equal(false,
                   fork.wait_child_terminated(1),
                   "metal boot has exited early")
      check_lambda = -> (hash) {
        ip = `gethostip -x #{hash[:nodename]}`.chomp
        assert_equal(ip,
                     `ls #{save} | grep #{ip}`.chomp,
                     "Could not find pxe file")
      }
      Alces::Stack::Iterator.run(@input_group[:group], check_lambda)
      fork.interrupt_child
      assert_equal(true,
                   fork.wait_child_terminated(4),
                   "metal boot has not finished")
      assert_empty(`ls /var/lib/tftpboot/pxelinux.cfg/`.chomp,
                   "Pxe file have not been deleted")
    }

    child_lambda = lambda { 
      Capture.stdout {
        Alces::Stack::Boot::Run.new(@input_group).run! 
      }
    }
    
    ForkProcess.new(parent_lambda, child_lambda).run
  end
end