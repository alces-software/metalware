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

require 'alces/stack/capture'

class TC_Hosts < Test::Unit::TestCase
  def setup
    `cp /etc/hosts /etc/hosts.copy.#{Process.pid}`
    @base_hosts = File.read("/etc/hosts")
    @bash = File.read("/etc/profile.d/alces-metalware.sh")
    @template = "test.erb"
    @template_str = "\nInsert into host <%= nodename %>"
    File.write("#{ENV['alces_BASE']}/etc/templates/hosts/#{@template}", @template_str)

  end

  def test_error_inputs
    output = Alces::Stack::Capture.stdout do puts `#{@bash} metal hosts 2>&1` end
    assert_equal("ERROR: Requires a node name, node group, or json\n", output, "Error expect for no nodename or group")
    output = Alces::Stack::Capture.stdout do puts `#{@bash} metal hosts -n nodes 2>&1` end
    assert_equal("ERROR: Could not modify hosts! No command included (e.g. --add).\nSee 'metal hosts -h'\n", output, "Ran without specifying mode")
  end

  def test_dry_run

  end

  def teardown
    `mv /etc/hosts.copy.#{Process.pid} /etc/hosts`
    `rm #{ENV['alces_BASE']}/etc/templates/hosts/#{@template}`
  end
end