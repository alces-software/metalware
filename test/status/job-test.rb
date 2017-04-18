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

require "alces/stack/status/job"

module Alces
  module Stack
    module Status
      class Job
        def bash_sleep
          run_bash("sleep 5d")
        end

        def return_100
          100
        end
      end
    end
  end
end

class TC_Status_Job < Test::Unit::TestCase
  def setup
    Alces::Stack::Status::Job.results = {}
    assert(Alces::Stack::Status::Job.results.empty?, "Results hash not empty")
  end

  def test_initialize
    nodename = "new_node"
    cmd = :new_cmd
    job = Alces::Stack::Status::Job.new(nodename, cmd)
    assert_equal(nodename,
                 job.instance_variable_get(:@nodename),
                 "Did not set the nodename correctly")
    assert_equal(cmd,
                 job.instance_variable_get(:@cmd),
                 "Did not set cmd correctly")
  end

  def _wait_for_timeout(thread)
    puts "\nTesting timeout, may take 10s"
    sleep_limit = 10
    while sleep_limit > 0 && thread.status == "sleep"
      sleep 1
      sleep_limit -= 1
    end
    assert(sleep_limit > 0, "Job did not timeout correctly")
    thread.join
  end

  def test_run_bash
    job = Alces::Stack::Status::Job.new("NOT USED", :bash_sleep)
    assert_equal(`sleep 1; ls`,
                 job.run_bash("ls"),
                 "Did not run simple bash command correctly")
    _wait_for_timeout job.start.thread
    assert_raise Errno::ESRCH do
      Process.kill 0, job.instance_variable_get(:@bash_pid)
    end
  end

  def test_reporting
    nodename = "slave04"
    cmd1 = :return_100
    cmd2 = :sleep
    Alces::Stack::Status::Job.new(nodename, cmd1).start
    job2 = Alces::Stack::Status::Job.new(nodename, cmd2).start
    sleep 2
    assert_equal("sleep",
                 job2.thread.status,
                 "Job was not started correctly")
    _wait_for_timeout(job2.thread)
    results = Alces::Stack::Status::Job.results
    assert(results.key?(nodename), "#{nodename} data not found, #{results}")
    assert_equal(100, results[nodename][cmd1], "Didn't report regular data")
    assert_equal("timeout", results[nodename][cmd2], "Didn't report timeout data")
  end
end