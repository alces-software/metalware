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

require 'config'
require 'constants'
require 'spec_utils'
require 'commands/build'

require 'minimal_repo'

# TODO: Could test rendering in these tests as well, though already doing in
# unit tests.

RSpec.describe '`metal build`', real_fs: true do
  METAL = Metalware::Constants::METAL_EXECUTABLE_PATH
  TEST_DIR = 'tmp/integration-test'
  CONFIG_FILE = SpecUtils.fixtures_config('integration-test.yaml')
  TEST_CONFIG = Metalware::Config.new(CONFIG_FILE)

  TEST_KICKSTART_DIR = File.join(TEST_CONFIG.rendered_files_path, 'kickstart')
  TEST_PXELINUX_DIR = TEST_CONFIG.pxelinux_cfg_path
  TEST_BUILT_NODES_DIR = TEST_CONFIG.built_nodes_storage_path

  TEST_REPO = File.join(TEST_DIR, 'repo')
  PXELINUX_TEMPLATE = File.join(TEST_REPO, 'pxelinux/default')

  AlcesUtils.start(self, config: CONFIG_FILE)

  def kill_any_metal_processes
    Thread.list.each do |t|
      t.exit unless t == Thread.current
    end
    `pkill nodeattr -9`
  end

  def wait_longer_than_build_poll
    # Hopefully longer enough than the `build_poll_sleep` that build process
    # notices whatever it needs to.
    sleep 2
  end

  def expect_clears_up_built_node_marker_files
    expect(Dir.empty?(TEST_BUILT_NODES_DIR)).to be true
  end

  def build_node(name, group: false)
    options = OpenStruct.new(group ? { group: true } : {})
    thr = Thread.new do
      begin
        Timeout.timeout 20 do
          Metalware::Commands::Build.new([name], options)
        end
      rescue => e
        STDERR.puts e.inspect
        STDERR.puts e.backtrace
      end
    end
    yield thr
  end

  before :each do
    kill_any_metal_processes

    SpecUtils.use_mock_genders(self)
    alces.nodes.each do |node|
      hex = node.name + '_HEX_IP'
      allow(node).to receive(:hexadecimal_ip).and_return(hex)
    end

    FileUtils.remove_dir(TEST_DIR, force: true)
    FileUtils.mkdir_p(TEST_KICKSTART_DIR)
    FileUtils.mkdir_p(TEST_PXELINUX_DIR)
    FileUtils.mkdir_p(TEST_BUILT_NODES_DIR)

    MinimalRepo.create_at(TEST_REPO)
  end

  after do
    kill_any_metal_processes
  end

  def touch_complete_file(node)
    file = "tmp/integration-test/built-nodes/metalwarebooter.#{node}"
    FileUtils.touch(file)
  end

  context 'for single node' do
    let :node { 'testnode01' }

    it 'works' do
      build_node(node) do |thread|
        wait_longer_than_build_poll
        expect(thread).to be_alive

        touch_complete_file(node)

        wait_longer_than_build_poll
        expect(thread.status).to eq(false)

        expect_clears_up_built_node_marker_files
      end
    end
  end

  context 'for gender group' do
    let :nodes { ['testnode01', 'testnode02', 'testnode03'] }

    it 'works' do
      build_node('nodes', group: true) do |thread|
        wait_longer_than_build_poll
        expect(thread).to be_alive

        touch_complete_file(nodes[0])
        wait_longer_than_build_poll
        expect(thread).to be_alive

        touch_complete_file(nodes[1])
        touch_complete_file(nodes[2])

        wait_longer_than_build_poll
        expect(thread.status).to eq(false)

        expect_clears_up_built_node_marker_files
      end
    end

    describe 'interrupt handling' do
      # Initial interrupt does not exit CLI; gives prompt for whether to
      # re-render all Pxelinux configs as if nodes all built.

      def expect_interrupt_does_not_kill(thread)
        thread.raise(Interrupt)
        wait_longer_than_build_poll
        expect(thread).to be_alive
      end

      def expect_interrupt_kills(thread)
        thread.raise(Interrupt)
        wait_longer_than_build_poll
        expect(thread.status).to be(false)
      end

      def expect_permanent_pxelinux_rendered_for_testnode01
        testnode01_pxelinux = File.read(
          File.join(TEST_PXELINUX_DIR, 'testnode01_HEX_IP')
        )
        expect(testnode01_pxelinux).to eq(
          Metalware::Templater.render(
            alces,
            PXELINUX_TEMPLATE,
            nodename: 'testnode01',
            firstboot: false
          )
        )
      end

      def expect_permanent_pxelinux_rendered_for_testnode02
        testnode01_pxelinux = File.read(
          File.join(TEST_PXELINUX_DIR, 'testnode02_HEX_IP')
        )
        expect(testnode01_pxelinux).to eq(
          Metalware::Templater.render(
            alces,
            PXELINUX_TEMPLATE,
            nodename: 'testnode02',
            firstboot: false
          )
        )
      end

      def expect_firstboot_pxelinux_rendered_for_testnode02
        testnode01_pxelinux = File.read(
          File.join(TEST_PXELINUX_DIR, 'testnode02_HEX_IP')
        )
        expect(testnode01_pxelinux).to eq(
          Metalware::Templater.render(
            alces,
            PXELINUX_TEMPLATE,
            nodename: 'testnode02',
            firstboot: true
          )
        )
      end

      it 'exits on second interrupt' do
        build_node('nodes', group: true) do |thread|
          touch_complete_file('testnode01')

          wait_longer_than_build_poll
          expect(thread).to be_alive

          expect_interrupt_does_not_kill(thread)
          expect_interrupt_kills(thread)
          expect_clears_up_built_node_marker_files

          expect_permanent_pxelinux_rendered_for_testnode01
          expect_permanent_pxelinux_rendered_for_testnode02
        end
      end

      context 'with mocked highline' do
        let :stdin { StringIO.new }
        let :highline { HighLine.new(stdin) }

        before :each do
          allow(HighLine).to receive(:new).and_return(highline)
        end

        it 'handles "yes" to interrupt prompt' do
          build_node('nodes', group: true) do |thread|
            stdin.puts('yes')
            stdin.rewind

            touch_complete_file('testnode01')

            wait_longer_than_build_poll
            expect(thread).to be_alive

            # Do not check if alive after the Interrupt
            # As it is directly raised, it exits faster than if it was a SIG
            thread.raise(Interrupt)

            wait_longer_than_build_poll
            expect(thread.status).to eq(false)
            expect_clears_up_built_node_marker_files

            expect_permanent_pxelinux_rendered_for_testnode01
            expect_permanent_pxelinux_rendered_for_testnode02
          end
        end

        it 'handles "no" to interrupt prompt' do
          build_node('nodes', group: true) do |thread|
            stdin.puts('no')
            stdin.rewind

            touch_complete_file('testnode01')

            wait_longer_than_build_poll
            expect(thread).to be_alive

            # Do not check if alive after Interrupt, there is a race condition
            thread.raise(Interrupt)

            wait_longer_than_build_poll
            expect(thread.status).to eq(false)
            expect_clears_up_built_node_marker_files

            expect_permanent_pxelinux_rendered_for_testnode01
            expect_firstboot_pxelinux_rendered_for_testnode02
          end
        end
      end
    end
  end
end
