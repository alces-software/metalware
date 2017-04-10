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

require "alces/stack/status/run"
require "alces/stack/status/monitor"

class TC_Status < Test::Unit::TestCase
  def setup
    @status_log = Alces::Stack::Log.create_log("/var/log/metalware/status.log")
    @status_log.progname = "status"
    @nodes = Array.new(10) { |i|
      if i < 9; "slave0#{i + 1}"
      else; "slave#{i + 1}"; end
    }
    @status_nodename = Alces::Stack::Status::Run.new(
      nodename: "slave04",
      group: nil,
      wait: 10,
      status_log: @status_log
    )
    @status_group = Alces::Stack::Status::Run.new(
      nodename: nil,
      group: "slave",
      wait: 10,
      status_log: @status_log
    )
  end

  def test_run_option_parsing
    assert_equal(["slave04"],
                 (@status_nodename.instance_variable_get :@opt).nodes,
                 "Did not pass nodename correctly")
    assert_equal(@nodes,
                 (@status_group.instance_variable_get :@opt).nodes,
                 "Did not generate node names from group correctly")
    assert_equal(10,
                 (@status_nodename.instance_variable_get :@opt).wait,
                 "Did not pass nodename correctly")
    assert_equal(@status_log,
                 (@status_nodename.instance_variable_get :@opt).status_log,
                 "Did not pass nodename correctly")
    assert_raise Alces::Stack::Status::Run::Options::InputError do
      Alces::Stack::Status::Run.new(
        nodename: "nodename",
        group: "group"
      )
    end
    assert_raise Alces::Stack::Status::Run::Options::InputError do
      Alces::Stack::Status::Run.new(
        nodename: nil,
        group: nil
      )
    end
  end

  def test_monitor_option_parsing
    options = {
      limit: 10,
      nodes: @nodes,
      cmds: [:cmd1, :cmd2],
      status_log: @status_log
    }
    opt = Alces::Stack::Status::Monitor.new(options).instance_variable_get :@opt
    assert_equal(options[:limit], opt.limit, "Did not pass the limit correctly")
    assert_equal(options[:nodes], opt.nodes, "Did not pass the nodes correctly")
    assert_equal(options[:cmds], opt.cmds, "Did not pass the cmds list correctly")
    assert_equal(options[:status_log], opt.status_log, "Did not pass status log correctly")
  end

  
end