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

class TC_Status_Run < Test::Unit::TestCase
  def test_get_finished_data
    run = Alces::Stack::Status::Run.new(group: "slave", thread_limit: 10, nodename: "")
    run_opt = run.instance_variable_get :@opt
    correct = {}
    ["slave01", "slave02"].each do |node|
      run_opt.cmds.each do |cmd|
        Alces::Stack::Status::Job.report_data(node, cmd, "test")
        correct[cmd] = "test"
      end
      Alces::Stack::Status::Job.report_data(node, :node_lable, node) #Testing purpose only
    end
    Alces::Stack::Status::Job.report_data("slave3", :ping, "not-complete")
    assert_equal(correct.merge({node_lable: "slave01"}),
                 run.get_finished_data,
                 "Did not return correct finished node")
    assert_equal(correct.merge({node_lable: "slave02"}),
                 run.get_finished_data,
                 "Did not return correct finished node")
    assert_equal(false, run.get_finished_data, "Returned an unfinished node")
    
    # Asserts finishes correctly
    run_opt.nodes.each do |node| 
      run_opt.cmds.each do |cmd|
        Alces::Stack::Status::Job.report_data(node, cmd, "test")
      end
      run.get_finished_data
    end
    assert_equal(Alces::Stack::Status::Run::Finished,
                 run.get_finished_data.class,
                 "Not returning nil when no nodes finished")
  end

  def test_display_data
    run = Alces::Stack::Status::Run.new(group: "slave", thread_limit: 10, nodename: "")
    run.display_data
  end  

  def teardown
    Alces::Stack::Status::Job.instance_variable_set(:@results, nil)
  end
end
