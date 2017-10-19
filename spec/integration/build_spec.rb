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
    `pkill bin/metal -f`
  end

  # Refer to http://stackoverflow.com/a/3568291/2620402.
  def process_exists?(pid)
    Process.getpgid(pid)
    true
  rescue Errno::ESRCH
    false
  end

  def wait_longer_than_build_poll
    # Hopefully longer enough than the `build_poll_sleep` that build process
    # notices whatever it needs to.
    sleep 2
  end

  def run_command(command)
    Timeout.timeout 20 do
      Open3.popen3 command do |stdin, stdout, stderr, thread|
        begin
          pid = thread.pid
          yield(stdin, stdout, stderr, pid)
        rescue IntentionallyCatchAnyException => e
          begin
            stdout_data = read_io_stream(stdout)
            stderr_data = read_io_stream(stderr)
            puts "stdout:\n#{stdout_data}\n\nstderr:\n#{stderr_data}"
          rescue
            raise e
          end
          raise
        end
      end
    end
  end

  def read_io_stream(stream)
    max_bytes_to_read = 30_000
    stream.read_nonblock(max_bytes_to_read)
  rescue EOFError
    ''
  end

  def expect_clears_up_built_node_marker_files
    expect(Dir.empty?(TEST_BUILT_NODES_DIR)).to be true
  end

  def build_node(name)
    thr = Thread.new do
      begin
        Timeout.timeout 20 do
          Metalware::Commands::Build.new([name], OpenStruct.new)
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
    allow_any_instance_of(Metalware::Namespaces::Node).to \
      receive(:hexadecimal_ip).and_return('HEX_IP')

    FileUtils.remove_dir(TEST_DIR, force: true)
    FileUtils.mkdir_p(TEST_KICKSTART_DIR)
    FileUtils.mkdir_p(TEST_PXELINUX_DIR)
    FileUtils.mkdir_p(TEST_BUILT_NODES_DIR)

    MinimalRepo.create_at(TEST_REPO)
  end

  after do
    kill_any_metal_processes
  end

  context 'for single node' do
    let :node { 'testnode01' }
    let :node_build_complete_path do
      'tmp/integration-test/built-nodes/metalwarebooter.testnode01'
    end

    it 'works' do
      build_node(node) do |thread|
        wait_longer_than_build_poll
        expect(thread).to be_alive

        FileUtils.touch(node_build_complete_path)
        wait_longer_than_build_poll
        expect(thread.status).to eq(false)

        expect_clears_up_built_node_marker_files
      end
    end
  end

  context 'for gender group' do
    xit 'works' do
      command = "#{METAL} build nodes --group --config #{CONFIG_FILE} --trace"
      run_command(command) do |_stdin, _stdout, _stderr, pid|
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be true

        FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode01')
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be true

        FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode02')
        FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode03')
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be false

        expect_clears_up_built_node_marker_files
      end
    end

    describe 'interrupt handling' do
      # Initial interrupt does not exit CLI; gives prompt for whether to
      # re-render all Pxelinux configs as if nodes all built.

      def expect_interrupt_does_not_kill(pid)
        Process.kill('INT', pid)
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be true
      end

      def expect_interrupt_kills(pid)
        Process.kill('INT', pid)
        wait_longer_than_build_poll
        expect(process_exists?(pid)).to be false
      end

      def expect_permanent_pxelinux_rendered_for_testnode01
        testnode01_pxelinux = File.read(
          File.join(TEST_PXELINUX_DIR, 'testnode01_HEX_IP')
        )
        expect(testnode01_pxelinux).to eq(
          Metalware::Templater.render(TEST_CONFIG, PXELINUX_TEMPLATE, nodename: 'testnode01', firstboot: false)
        )
      end

      def expect_permanent_pxelinux_rendered_for_testnode02
        testnode01_pxelinux = File.read(
          File.join(TEST_PXELINUX_DIR, 'testnode02_HEX_IP')
        )
        expect(testnode01_pxelinux).to eq(
          Metalware::Templater.render(TEST_CONFIG, PXELINUX_TEMPLATE, nodename: 'testnode02', firstboot: false)
        )
      end

      def expect_firstboot_pxelinux_rendered_for_testnode02
        testnode01_pxelinux = File.read(
          File.join(TEST_PXELINUX_DIR, 'testnode02_HEX_IP')
        )
        expect(testnode01_pxelinux).to eq(
          Metalware::Templater.render(TEST_CONFIG, PXELINUX_TEMPLATE, nodename: 'testnode02', firstboot: true)
        )
      end

      xit 'exits on second interrupt' do
        command = "#{METAL} build nodes --group --config #{CONFIG_FILE} --trace"
        run_command(command) do |_stdin, _stdout, _stderr, pid|
          FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode01')
          wait_longer_than_build_poll
          expect(process_exists?(pid)).to be true

          expect_interrupt_does_not_kill(pid)
          expect_interrupt_kills(pid)
          expect_clears_up_built_node_marker_files

          expect_permanent_pxelinux_rendered_for_testnode01
          expect_permanent_pxelinux_rendered_for_testnode02
        end
      end

      xit 'handles "yes" to interrupt prompt' do
        command = "#{METAL} build nodes --group --config #{CONFIG_FILE} --trace"
        run_command(command) do |stdin, _stdout, _stderr, pid|
          FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode01')
          wait_longer_than_build_poll
          expect(process_exists?(pid)).to be true

          expect_interrupt_does_not_kill(pid)

          stdin.puts('yes')
          wait_longer_than_build_poll
          expect(process_exists?(pid)).to be false
          expect_clears_up_built_node_marker_files

          expect_permanent_pxelinux_rendered_for_testnode01
          expect_permanent_pxelinux_rendered_for_testnode02
        end
      end

      xit 'handles "no" to interrupt prompt' do
        command = "#{METAL} build nodes --group --config #{CONFIG_FILE} --trace"
        run_command(command) do |stdin, _stdout, _stderr, pid|
          FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode01')
          wait_longer_than_build_poll
          expect(process_exists?(pid)).to be true

          expect_interrupt_does_not_kill(pid)

          stdin.puts('no')
          wait_longer_than_build_poll
          expect(process_exists?(pid)).to be false
          expect_clears_up_built_node_marker_files

          expect_permanent_pxelinux_rendered_for_testnode01
          expect_firstboot_pxelinux_rendered_for_testnode02
        end
      end
    end
  end
end
