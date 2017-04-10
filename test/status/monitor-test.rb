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

require "alces/stack/status/monitor"

class TC_Status < Test::Unit::TestCase
  def setup
    @status_log = Alces::Stack::Log.create_log("/var/log/metalware/status.log")
    @status_log.progname = "status"
    @nodes = Array.new(10) do |i|
      if i < 9; "slave0#{i + 1}"
      else; "slave#{i + 1}"; end
    end
    @options = {
      limit: 10,
      nodes: @nodes,
      cmds: [:cmd1, :cmd2],
      status_log: @status_log
    }
    @monitor = Alces::Stack::Status::Monitor.new(@options)
  end

  def test_option_parsing
    opt = @monitor.instance_variable_get :@opt
    assert_equal(@options[:limit], opt.limit, "Did not pass the limit correctly")
    assert_equal(@options[:nodes], opt.nodes, "Did not pass the nodes correctly")
    assert_equal(@options[:cmds], opt.cmds, "Did not pass the cmds list correctly")
    assert_equal(@options[:status_log], opt.status_log, "Did not pass status log correctly")
  end

  def test_add_job_queue
    (0...9).each do |i|
      @monitor.add_job_queue("random_node#{i}", "random_cmd#{i}".to_sym)
    end
    queue = @monitor.instance_variable_get :@queue
    assert_equal(10, queue.length, "10 jobs where not added to the queue")
    assert_equal("random_node5", queue[5][:nodename], "Nodename not correct")
    assert_equal("random_cmd5".to_sym, queue[5][:cmd], "Cmd not correct")
  end
end