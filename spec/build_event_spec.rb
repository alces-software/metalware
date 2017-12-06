# frozen_string_literal: true

require 'build_event'
require 'alces_utils'

RSpec.describe Metalware::BuildEvent do
  include AlcesUtils

  let :nodes { ['node01', 'node02', 'node03', 'nodes4'] }
  let :built_node { nodes[2] }
  let :build_event { Metalware::BuildEvent.new(alces.nodes) }
  let :empty_build_event { Metalware::BuildEvent.new([]) }

  AlcesUtils.mock self, :each do
    nodes.each { |node| mock_node(node) }
    Thread.list.each { |t| t.kill unless t == Thread.current }
  end

  def wait_for_hooks_to_run(test_obj: build_event)
    Timeout.timeout 3 do
      sleep 0.1 while test_obj.hook_active?
    end
  end

  describe '#run_start_hooks' do
    it 'runs the start_hook for each node' do
      alces.nodes.each do |node|
        expect(node.build_method).to receive(:start_hook)
      end
      build_event.run_start_hooks
      wait_for_hooks_to_run
    end
  end

  describe '#build_complete?' do
    it 'returns true if initialized with no nodes' do
      expect(empty_build_event.build_complete?).to eq(true)
    end

    it 'returns false if a hook is still active' do
      empty_build_event.send(:run_hook) { sleep 0 }
      expect(empty_build_event.build_complete?).to eq(false)
    end

    it 'returns false if the nodes have not finished building' do
      expect(build_event.build_complete?).to eq(false)
    end
  end

  describe '#hook_active?' do
    it 'returns false if no hooks are running' do
      expect(build_event.hook_active?).to eq(false)
    end

    it 'returns true if there is a running thread' do
      build_event.send(:run_hook) { sleep 0 }
      expect(build_event.hook_active?).to eq(true)
    end

    it 'returns false once the thread has finished' do
      build_event.send(:run_hook) { sleep 0.1 }
      expect(build_event.hook_active?).to eq(true)
      wait_for_hooks_to_run
      expect(build_event.hook_active?).to eq(false)
    end
  end

  describe '#kill_threads' do
    it 'kills all the threads' do
      build_event.send(:run_hook) { sleep 0 }
      build_event.send(:run_hook) { sleep 0 }
      build_event.kill_threads
      wait_for_hooks_to_run
      expect(build_event.hook_active?).to eq(false)
    end
  end
end
