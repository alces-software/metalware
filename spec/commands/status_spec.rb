# frozen_string_literal: true

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

require 'commands/status'
require 'status/monitor'
require 'status/job'
require 'spec_utils'
require 'timeout'
require 'namespaces/alces'
require 'filesystem'

RSpec.describe Metalware::Status::Monitor do
  include AlcesUtils

  before do
    FileSystem.root_setup do |fs|
      fs.with_genders_fixtures
      fs.with_clone_fixture('configs/unit-test.yaml')
    end
    @nodes = alces.nodes.map(&:name)
    @cmds = [:ping, :power]
    @m_input = { nodes: @nodes, cmds: @cmds, thread_limit: 10, time_limit: 20 }
    @monitor = described_class.new(@m_input)
  end

  context 'after the monitor is initialized' do
    it 'contains a empty job queue and running list' do
      expect(@monitor.instance_variable_get(:@running)).to eq([])
      queue = @monitor.instance_variable_get :@queue
      expect(queue).to be_a(Queue)
      expect(queue.length).to eq(0)
    end
  end

  context 'create_jobs is ran' do
    before do
      @monitor.instance_eval { @started_jobs = 0 }
      @monitor.define_singleton_method(:start_next_job,
                                       ->(_idx) { @started_jobs += 1 })
      @monitor.create_jobs
    end

    it 'adds all the nodes and commands' do
      opt = @monitor.instance_variable_get :@opt
      queue_length = opt.cmds.length * opt.nodes.length
      queue = @monitor.instance_variable_get :@queue
      expect(queue.length).to eq(queue_length)
    end

    it 'start_next_job is ran' do
      expect(@monitor.instance_variable_get(:@started_jobs))
        .to eq(@m_input[:thread_limit])
    end

    it 'adds commands then nodes' do
      queue = @monitor.instance_variable_get :@queue
      @cmds.each do |c|
        job = queue.pop
        expect(job[:cmd]).to eq(c)
        expect(job[:nodename]).to eq(@nodes[0])
      end
      job = queue.pop
      expect(job[:cmd]).to eq(@cmds[0])
      expect(job[:nodename]).to eq(@nodes[1])
    end
  end
end
