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
require 'filesystem'

RSpec.describe Metalware::Status::Monitor do
  include AlcesUtils

  let(:nodes) { alces.nodes.map(&:name) }

  before do
    FileSystem.root_setup(&:with_genders_fixtures)
    SpecUtils.use_mock_genders(self)
    @cmds = [:ping, :power]
    @m_input = { nodes: nodes, cmds: @cmds, thread_limit: 10, time_limit: 20 }
    @monitor = described_class.new(@m_input)
  end

  after do
    Thread.list.each do |t|
      unless t == Thread.current
        t.kill
        t.join
      end
    end
  end

  context 'when threading jobs' do
    before do
      allow_any_instance_of(Metalware::Status::Job).to receive(:start) {
        t = Thread.new { sleep }
        t.define_singleton_method(:thread, -> { self })
        t
      }
    end

    it 'add_job_queue adds and start_next_job starts jobs' do
      queue = @monitor.instance_variable_get(:@queue)
      running = @monitor.instance_variable_get(:@running)

      num_nodes = 10
      num_nodes.times do |i|
        @monitor.add_job_queue("node#{i}", :ping)
      end

      expect(queue.length).to eq(num_nodes)
      expect(running.length).to eq(0)

      # Starts the jobs
      num_nodes.times do |i|
        idx = i**2
        @monitor.start_next_job(idx)
      end

      # Test the threads are sleeping (NOTE: Job.start has been stubbed)
      sleep 0.001 # Their is a race condition, may causes failures
      num_nodes.times do |i|
        idx = i**2
        job = running[idx]
        expect(job.alive?).to eq(job.stop?)
      end

      expect(queue.length).to eq(0)
    end

    it 'monitor_jobs runs until complete' do
      @monitor.create_jobs
      num_jobs = @m_input[:nodes].length * @m_input[:cmds].length

      queue = @monitor.instance_variable_get(:@queue)
      running = @monitor.instance_variable_get(:@running)
      expect(running.length).to eq(@m_input[:thread_limit])
      expect(queue.length).to eq(num_jobs - @m_input[:thread_limit])
      expect(queue.length).to be > 0 # NO POINT TESTING IF THIS FAILS

      monitor_thr = Thread.new { @monitor.monitor_jobs }

      Timeout.timeout(15) do
        until queue.empty?
          cur_len = queue.length
          running.sample.thread.kill
          sleep 0.001 until queue.length == cur_len - 1
        end
        until running.empty?
          t = running.sample
          t&.thread&.kill
        end
        monitor_thr.join
      end
    end
  end
end
