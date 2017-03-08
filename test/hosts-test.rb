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

require 'alces/stack/capture'
require "alces/stack/hosts"
require "alces/stack/templater"

class TC_Hosts < Test::Unit::TestCase
  def setup
    `cp /etc/hosts /etc/hosts.copy.#{Process.pid}`
    @base_hosts = File.read("/etc/hosts")
    @bash = File.read("/etc/profile.d/alces-metalware.sh")
    @template = "test.erb"
    @template_str = "\nInsert into host, nodename: <%= nodename %>"
    File.write("#{ENV['alces_BASE']}/etc/templates/hosts/#{@template}", @template_str)

  end

  def test_error_inputs
    output = Capture.stdout do puts `#{@bash} metal hosts 2>&1` end
    assert_equal("ERROR: Requires a node name, node group, or json\n", output, "Error expect for no nodename or group")
    output = Capture.stdout do puts `#{@bash} metal hosts -n nodes 2>&1` end
    assert_equal("ERROR: Could not modify hosts! No command included (e.g. --add).\nSee 'metal hosts -h'\n", output, "Ran without specifying mode")
  end

  def test_add_host_dry_run
    nodename = "node"
    output = Capture.stdout do puts `#{@bash} metal hosts -ax -n #{nodename} -t #{@template} 2>&1` end
    correct_output = Alces::Stack::Templater::Handler.new.replace_erb(@template_str, {nodename: nodename})
    assert_equal(correct_output, output.chomp, "Did not replace_erb correctly")
  end

  def test_add_host
    nodename = "node"
    `#{@bash} metal hosts -a -n #{nodename} -t #{@template}`
    correct_output = Alces::Stack::Templater::Handler.new.replace_erb(@template_str, {nodename: nodename})
    correct_output = "#{@base_hosts}#{correct_output}"
    assert_equal(correct_output, File.read("/etc/hosts").chomp, "Did not append to file correctly")
  end

  def teardown
    `mv /etc/hosts.copy.#{Process.pid} /etc/hosts`
    `rm #{ENV['alces_BASE']}/etc/templates/hosts/#{@template}`
  end
end