# frozen_string_literal: true

require 'build_event'
require 'alces_utils'

module Metalware
  class BuildEvent
    def test_thread
      build_threads.push(Thread.new { yield })
    end
  end
end

RSpec.describe Metalware::BuildEvent do
  include AlcesUtils

  let(:nodes) { ['node01', 'node02', 'node03', 'nodes4'] }
  let(:build_event) { described_class.new(alces.nodes) }
  let(:empty_build_event) { described_class.new([]) }

  AlcesUtils.mock self, :each do
    nodes.each { |node| mock_node(node) }
    alces.nodes.each { |node| hexadecimal_ip(node) }
    AlcesUtils.kill_other_threads
  end

  def wait_for_hooks_to_run(test_obj: build_event)
    Timeout.timeout 3 do
      sleep 0.001 while test_obj.hook_active?
    end
  end

  def build_node(node)
    touch_file node.build_complete_path
  end

  def touch_file(path)
    FileUtils.mkdir_p File.dirname(path)
    FileUtils.touch path
  end

  describe '#run_all_complete_hooks' do
    it 'runs the complete hook for each node' do
      alces.nodes.each do |node|
        expect(node.build_method).to receive(:complete_hook).once
      end
      build_event.run_all_complete_hooks
      wait_for_hooks_to_run
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

  describe '#process' do
    def process(test_obj: build_event)
      AlcesUtils.redirect_std(:stdout, :stderr) do
        test_obj.process
        wait_for_hooks_to_run(test_obj: test_obj)
      end
    end

    context 'with a single node built' do
      let(:built_node) { alces.nodes[2] }

      before { build_node(built_node) }

      it 'runs the complete_hook for the node' do
        expect(built_node.build_method).to receive(:complete_hook)
        process
      end

      it 'deletes the build file' do
        process
        expect(File.exist?(built_node.build_complete_path)).to eq(false)
      end

      it 'only builds the node once' do
        expect(built_node.build_method).to receive(:complete_hook).once
        process
        build_node(built_node)
        process
      end

      it 'does not finish the build' do
        process
        expect(build_event.build_complete?).to eq(false)
      end
    end

    context 'with all the nodes built' do
      before { alces.nodes.each { |node| build_node(node) } }

      it 'runs all the complete hooks' do
        alces.nodes.each do |node|
          expect(node.build_method).to receive(:complete_hook)
        end
        process
      end

      it 'deletes all the build files' do
        process
        alces.nodes.each do |node|
          expect(File.exist?(node.build_complete_path)).to eq(false)
        end
      end

      it 'finishes the build' do
        process
        expect(build_event.build_complete?).to eq(true)
      end
    end

    context 'with an event trigger' do
      let(:node) { alces.nodes[3] }
      let(:event) { '__trigger_without_a_build_method_hook__' }
      let(:event_file) { Metalware::FilePath.event(node, event) }

      context 'with basic features only (no hooks nor messages)' do
        before { touch_file event_file }

        it 'reports the event and node names to stdout' do
          expect(process[:stdout].read).to include(node.name, event)
        end

        it 'deletes the file' do
          process
          expect(File.exist?(event_file)).to eq(false)
        end
      end

      context 'with a message' do
        let(:message_arr) do
          ['I am a little message', 'With multiple lines', 'potato']
        end

        before do
          FileUtils.mkdir_p File.dirname(event_file)
          File.write(event_file, message_arr.join("\n"))
        end

        it 'displays the message' do
          expect(process[:stdout].read).to include(*message_arr)
        end
      end
    end
  end

  describe '#build_complete?' do
    it 'returns true if initialized with no nodes' do
      expect(empty_build_event.build_complete?).to eq(true)
    end

    it 'returns false if a hook is still active' do
      empty_build_event.test_thread { sleep 0 }
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
      build_event.test_thread { sleep 0 }
      expect(build_event.hook_active?).to eq(true)
    end

    it 'returns false once the thread has finished' do
      build_event.test_thread { sleep 0.1 }
      expect(build_event.hook_active?).to eq(true)
      wait_for_hooks_to_run
      expect(build_event.hook_active?).to eq(false)
    end
  end

  describe '#kill_threads' do
    it 'kills all the threads' do
      build_event.test_thread { sleep 0 }
      build_event.test_thread { sleep 0 }
      build_event.kill_threads
      wait_for_hooks_to_run
      expect(build_event.hook_active?).to eq(false)
    end

    it 'hangs until all the threads have been killed' do
      init_th = Thread.list
      10.times { build_event.test_thread { sleep 0 } }
      build_threads = Thread.list.reject { |t| init_th.include?(t) }
      build_event.kill_threads
      expect(Thread.list).not_to include(*build_threads)
    end
  end
end
