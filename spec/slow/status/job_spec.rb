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

RSpec.describe Metalware::Status::Job do
  let(:job) { described_class.new(node, cmd, time_limit) }
  let(:cmd) { :busy_sleep }
  let(:node) { 'node_name_not_found' }
  let(:time_limit) { 2 }

  before do
    described_class.send(:define_method, :busy_sleep, lambda {
      until 1 == 2; end
    })
    described_class.send(:define_method, :bash_sleep, lambda {
      run_bash('sleep 100')
    })
    SpecUtils.use_mock_genders(self)
  end

  after do
    Thread.list.each do |t|
      unless t == Thread.current
        t.kill
        t.join
      end
    end
    described_class.instance_variable_set(:@results, nil)
  end

  it 'initializes the instance variables' do
    expect(job.instance_variable_get(:@nodename)).to eq(node)
    expect(job.instance_variable_get(:@cmd)).to eq(cmd)
    expect(job.instance_variable_get(:@time_limit)).to eq(time_limit)
  end

  it 'runs bash commands' do
    output = 'STDOUT'
    cmd = "echo -n \"#{output}\""
    expect(job.instance_variable_get(:@bash_pid)).to eq(nil)
    expect(job.run_bash(cmd)).to eq(output)
    expect(job.instance_variable_get(:@bash_pid)).not_to eq(nil)
  end

  it 'kills bash commands' do
    job.instance_variable_set(:@cmd, :bash_sleep)
    job.start
    sleep time_limit / 2
    job.thread.kill
    job.thread.join
    expect do
      Process.kill(0, job.instance_variable_get(:@bash_pid))
    end.to raise_error(Errno::ESRCH)
  end

  context 'when started' do
    it 'busy_sleep timesout and reports results' do
      Timeout.timeout(time_limit + 1) do
        job.start
        sleep time_limit / 2
        expect(job.thread.alive?).to eq(true)
        job.thread.join
      end

      results = described_class.results
      expect(results).to eq(node => {
                              cmd => 'timeout',
                            })
    end

    it 'calls commands through CLI library' do
      job.define_singleton_method(:job_power_status, -> { 'POWER_STATUS' })
      job.define_singleton_method(:job_ping_node, -> { 'PING_NODE' })

      job.instance_variable_set(:@cmd, :ping)
      job.start
      job.thread.join

      job.instance_variable_set(:@cmd, :power)
      job.start
      job.thread.join

      expect(described_class.results).to eq(node => {
                                              ping: 'PING_NODE',
                                              power: 'POWER_STATUS',
                                            })
    end
  end
end
