
require 'config'
require 'constants'
require 'spec_utils'

# TODO: Could test rendering in these tests as well, though already doing in
# unit tests.

describe '`metal build`' do
  METAL = File.join(Metalware::Constants::METALWARE_INSTALL_PATH, 'bin/metal')
  TEST_DIR = 'tmp/integration-test'
  CONFIG_FILE = SpecUtils.fixtures_config('integration-test.yaml')
  TEST_CONFIG = Metalware::Config.new(CONFIG_FILE)

  TEST_KICKSTART_DIR = File.join(TEST_CONFIG.rendered_files_path, 'kickstart')
  TEST_PXELINUX_DIR = TEST_CONFIG.pxelinux_cfg_path
  TEST_BUILT_NODES_DIR = TEST_CONFIG.built_nodes_storage_path

  def kill_any_metal_processes
    `pkill bin/metal --full`
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
    sleep 0.3
  end

  def fork_command(command)
    pid = fork do
      exec command
    end
    Process.detach(pid)
    pid
  end

  def expect_clears_up_built_node_marker_files
    expect(Dir.empty?(TEST_BUILT_NODES_DIR)).to be true
  end

  before :each do
    kill_any_metal_processes

    ENV['PATH'] = "spec/fixtures/libexec/:#{ENV['PATH']}"

    FileUtils.remove_dir(TEST_DIR, force: true)
    FileUtils.mkdir_p(TEST_KICKSTART_DIR)
    FileUtils.mkdir_p(TEST_PXELINUX_DIR)
    FileUtils.mkdir_p(TEST_BUILT_NODES_DIR)

    if !File.exists? 'tmp/repo'
      `git clone https://github.com/alces-software/metalware-default.git tmp/repo`
      `cd tmp/repo && git checkout feature/adaptations-for-new-metalware`
    end
  end

  after do
    kill_any_metal_processes
  end

  context 'for single node' do
    it 'works' do
      metal_pid = fork_command "#{METAL} build node01 --config #{CONFIG_FILE} --trace"

      wait_longer_than_build_poll
      expect(process_exists?(metal_pid)).to be true

      FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.node01')
      wait_longer_than_build_poll
      expect(process_exists?(metal_pid)).to be false

      expect_clears_up_built_node_marker_files
    end
  end

  context 'for gender group' do
    it 'works' do
      metal_pid = fork_command "#{METAL} build nodes --group --config #{CONFIG_FILE} --trace"

      wait_longer_than_build_poll
      expect(process_exists?(metal_pid)).to be true

      FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode01')
      wait_longer_than_build_poll
      expect(process_exists?(metal_pid)).to be true

      FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode02')
      FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.testnode03')
      wait_longer_than_build_poll
      expect(process_exists?(metal_pid)).to be false

      expect_clears_up_built_node_marker_files
    end

    it 'handles interrupt' do
      metal_pid = fork_command "#{METAL} build nodes --group --config #{CONFIG_FILE} --trace"

      wait_longer_than_build_poll
      FileUtils.touch('tmp/integration-test/built-nodes/metalwarebooter.node01')
      wait_longer_than_build_poll

      expect(process_exists?(metal_pid)).to be true

      Process.kill("INT", metal_pid)
      wait_longer_than_build_poll

      expect(process_exists?(metal_pid)).to be false
      expect_clears_up_built_node_marker_files
    end
  end
end
