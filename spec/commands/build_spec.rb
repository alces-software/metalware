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

require 'timeout'

require 'commands/build'
require 'spec_utils'
require 'recursive_open_struct'
require 'network'
require 'alces_utils'

RSpec.describe Metalware::Commands::Build do
  include AlcesUtils

  before do
    # Shortens the wait times for the tests
    stub_const('Metalware::Constants::BUILD_POLL_SLEEP', 0.1)
    # Makes sure there aren't any other threads
    AlcesUtils.kill_other_threads
  end

  let(:build_wait_time) { Metalware::Constants::BUILD_POLL_SLEEP * 5 }

  def run_build(node_group, delay_report_built: nil, **options_hash)
    Timeout.timeout build_wait_time do
      th = Thread.new do
        AlcesUtils.redirect_std(:stdout) do
          Metalware::Utils.run_command(
            Metalware::Commands::Build, node_group.name, **options_hash
          )
        end
      end

      # Allows the build to report finished after a set delay
      if delay_report_built
        sleep delay_report_built
        if node_group.is_a?(Metalware::Namespaces::Node)
          [node_group]
        else
          node_group.nodes
        end.each do |node|
          path = node.build_complete_path
          FileUtils.mkdir_p File.dirname(path)
          FileUtils.touch path
        end
      end
      th.join
    end
  end

  # Sets up the filesystem
  before do
    FileSystem.root_setup do |fs|
      fs.with_repo_fixtures('repo')
      fs.with_genders_fixtures
    end
  end

  # Mocks the test node
  let(:testnode) { alces.nodes.find_by_name('testnode01') }

  AlcesUtils.mock self, :each do
    config(testnode, build_method: :kickstart)
    hexadecimal_ip(testnode)
  end

  before do
    SpecUtils.use_mock_dependency(self)
  end

  context 'when called without group argument' do
    context 'with a node that builds successfully' do
      it 'calls the start_hook' do
        expect(testnode.build_method).to receive(:start_hook).once
        run_build(testnode, delay_report_built: build_wait_time / 10)
      end

      it 'calls the complete_hook' do
        expect(testnode.build_method).to receive(:complete_hook).once
        run_build(testnode, delay_report_built: build_wait_time / 10)
      end
    end

    context 'with an incomplete build' do
      def incomplete_build
        th = Thread.new { run_build(testnode) }
        sleep(build_wait_time / 10)
        th.raise(Interrupt) while th.alive?
      end

      it 'calls the start hook' do
        expect(testnode.build_method).to receive(:start_hook)
        incomplete_build
      end

      it 'does not call the complete hook' do
        expect(testnode.build_method).not_to receive(:complete_hook)
        incomplete_build
      end
    end
  end

  context 'when called for group' do
    AlcesUtils.mock self, :each do
      test_group = test_group_name
      mock_group(test_group)
      ['nodeA00', 'nodeA01', 'nodeA02', 'nodeA03'].each do |node|
        hexadecimal_ip(mock_node(node, test_group))
      end
    end

    let(:test_group_name) { 'some_random_test_group' }
    let(:testnodes) { alces.groups.find_by_name test_group_name }
    let(:delay_build) { build_wait_time / 10 }

    it 'starts all the builds' do
      testnodes.nodes do |node|
        expect(node).to receive(:start_hook).once
      end
      run_build(testnodes, delay_report_built: delay_build, gender: true)
    end

    it 'completes all the nodes once built' do
      testnodes.nodes do |node|
        expect(node).to receive(:complete_hook).once
      end
      run_build(testnodes, delay_report_built: delay_build, gender: true)
    end

    it 'finishes once all the nodes are built' do
      expect do
        run_build(testnodes, delay_report_built: delay_build, gender: true)
      end.not_to raise_error
    end

    context 'with a single node that has not been built' do
      def build_all_but_one_node
        built_nodes = testnodes.nodes.dup
        built_nodes.shift # The first node will not be built
        th = Thread.new do
          run_build(testnodes, gender: true)
          sleep(build_wait_time / 10)
          built_nodes.each { |n| FileUtils n.build_complete_path }
        end
        th.join
      end

      it 'hangs if a node has not finish building' do
        expect do
          build_all_but_one_node
        end.to raise_error(Timeout::Error)
      end

      it 'cleans up all the build files' do
        begin
          build_all_but_one_node
          raise 'Test should intentionally timeout'
        rescue Timeout::Error
          path = File.dirname(testnodes.nodes.first.build_complete_path)
          build_complete_files = Dir[File.join(path, '**/*')]
          expect(build_complete_files).to be_empty
        end
      end
    end
  end
end
