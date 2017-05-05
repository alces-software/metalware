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

module Alces
  module Stack
    module Status
      class Job
        def pause
          sleep 1
        end

        def bash_pause
          run_bash("sleep 1")
        end
      end
    end
  end
end

class TC_Status_Monitor < Test::Unit::TestCase
  def setup
    @status_log = Alces::Stack::Log.create_log("/var/log/metalware/status.log")
    @status_log.progname = "status"
    @nodes = Array.new(10) do |i|
      if i < 9; "slave0#{i + 1}"
      else; "slave#{i + 1}"; end
    end
    @options = {
      thread_limit: 10,
      time_limit: 10,
      nodes: @nodes,
      cmds: [:bash_pause, :pause],
      status_log: @status_log
    }
    @monitor = Alces::Stack::Status::Monitor.new(@options)
  end

  def test_option_parsing
    opt = @monitor.instance_variable_get :@opt
    assert_equal(@options[:thread_limit], opt.thread_limit, "Did not pass the limit correctly")
    assert_equal(@options[:nodes], opt.nodes, "Did not pass the nodes correctly")
    assert_equal(@options[:cmds], opt.cmds, "Did not pass the cmds list correctly")
    assert_equal(@options[:status_log], opt.status_log, "Did not pass status log correctly")
  end

  def test_add_job_queue
    (0...10).each do |i|
      @monitor.add_job_queue("random_node#{i}", "random_cmd#{i}".to_sym)
    end
    queue = @monitor.instance_variable_get :@queue
    assert_equal(10, queue.length, "10 jobs where not added to the queue")
    value = queue.pop
    assert_equal("random_node0", value[:nodename], "Nodename not correct")
    assert_equal("random_cmd0".to_sym, value[:cmd], "Cmd not correct")
  end

  def test_start_next_job
    (0...10).each do |i|
      @monitor.add_job_queue("random_node#{i}", :sleep)
    end
    queue = @monitor.instance_variable_get :@queue
    old_queue_length = queue.length
    old_number_threads = Thread.list.length
    @monitor.start_next_job(0)
    assert_equal(old_queue_length, queue.length + 1, "Did not pop job off queue")
    assert_equal(old_number_threads + 1, Thread.list.length,
                 "Did not start next job")
  end

  def test_create_jobs
    num_jobs = @options[:cmds].length * @options[:nodes].length - @options[:thread_limit]
    @monitor.create_jobs
    assert_equal(num_jobs,
                 @monitor.instance_variable_get(:@queue).length,
                 "Did not start the correct number of processes")
    assert_equal(@options[:thread_limit],
                 @monitor.instance_variable_get(:@running).length,
                 "Did not record all the running threads")
  end

  def test_start
    puts "\nTest start monitor, may take 10s"
    @monitor.start
    @monitor.thread.join
    assert_equal(1, Thread.list.length, "Job threads have not been terminated")
    queue = @monitor.instance_variable_get :@queue
    assert_equal(0, queue.length, "Queue is not empty")
    running = @monitor.instance_variable_get :@running
    assert_equal(0, running.length, "Running jobs still exists")
  end

  def teardown
    Thread.list.each { |t| t.exit unless t == Thread.current }
    Alces::Stack::Status::Job.instance_variable_set(:@results, nil)
  end
end