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
require 'config'
require 'recursive_open_struct'
require 'network'
require 'alces_utils'

# Allows the templates method to be spoofed
module Metalware
  module HashMergers
    class MetalRecursiveOpenStruct
      def templates
        self[:templates]
      end
    end
  end
end

RSpec.describe Metalware::Commands::Build do
  include AlcesUtils

  before :each do
    Thread.list.each do |th|
      th.kill unless th == Thread.main
    end
  end

  def run_build(node_identifier, **options_hash)
    # Run command in timeout as `build` will wait indefinitely, but want to
    # abort tests if it looks like this is happening.
    Timeout.timeout 0.5 do
      Metalware::Utils.run_command(
        Metalware::Commands::Build, node_identifier, **options_hash
      )
    end
  end

  # TODO: Remove this method, mock using AlcesUtils
  # Makes `Node.new` return real `Node`s, but with certain methods stubbed to
  # not depend on environment.
  def use_mock_nodes(not_built_nodes: [])
    allow(
      Metalware::Namespaces::Node
    ).to receive(:new).and_wrap_original do |original_new, *args|
      original_new.call(*args).tap do |node|
        # Stub this as depends on `gethostip` and `/etc/hosts`
        allow(node).to receive(:hexadecimal_ip).and_return(node.name + '_HEX_IP')
      end
    end

    allow_any_instance_of(Metalware::Commands::Build).to \
      receive(:built?).and_wrap_original do |_original, node|
      !not_built_nodes.include?(node.name)
    end
  end

  def expect_runs_longer_than(seconds, &block)
    expect do
      Timeout.timeout(seconds, &block)
    end.to raise_error Timeout::Error
  end

  def expect_renders(template_path, to:)
    expect(Metalware::Templater).to receive(:render_to_file).with(
      instance_of(Metalware::Namespaces::Node),
      template_path,
      to,
      instance_of(Hash)
    )
  end

  let :testnodes_config_path do
    metal_config.repo_config_path('testnodes')
  end

  # Sets up the filesystem
  before :each do
    FileSystem.root_setup do |fs|
      fs.with_repo_fixtures('repo')
      fs.with_genders_fixtures('genders/simple_cluster')
    end
  end

  before :each do
    SpecUtils.fake_download_error(self)
    SpecUtils.use_mock_dependency(self)
  end

  context 'when called without group argument' do
    it 'renders default standard templates for given node' do
      expect_renders(
        "#{metal_config.repo_path}/pxelinux/default",
        to: '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
      ).at_least(:once)

      run_build('testnode01')
    end

    context 'when templates specified in repo config' do
      let :testnode01_config do
        OpenStruct.new(
          pxelinux: 'repo_pxelinux',
          kickstart: 'repo_kickstart'
        )
      end

      before :each do
        allow(alces.nodes.testnode01.config).to \
          receive(:templates).and_return(testnode01_config)
        allow(alces.nodes.testnode02.config).to \
          receive(:templates).and_return(OpenStruct.new)
      end

      it 'uses specified templates' do
        expect_renders(
          "#{metal_config.repo_path}/pxelinux/repo_pxelinux",
          to: '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
        ).at_least(:once)

        run_build('testnode01')
      end

      it 'specifies correct template dependencies' do
        groups = Metalware::Namespaces::MetalArray.new(
          [Metalware::Namespaces::Group.new(alces, 'cluster', index: 1)]
        )
        allow(alces).to receive(:groups).and_return(groups)

        build_command = run_build('cluster', group: true)

        # Not ideal to test private method, but seems best way in this case.
        dependency_hash = build_command.send(:dependency_hash)

        expect(dependency_hash[:repo].sort).to eq([
          # `default` templates used for node `testnode02`.
          'pxelinux/default',
          'kickstart/default',

          # Repo templates for 'testnode01'
          'pxelinux/repo_pxelinux',
          'kickstart/repo_kickstart',
        ].sort)
      end
    end

    it 'renders pxelinux once with firstboot true if node does not build' do
      time_to_wait = 0.2
      use_mock_nodes(not_built_nodes: 'testnode01')

      expect_renders(
        "#{metal_config.repo_path}/pxelinux/default",
        to: '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
      ).once

      expect_runs_longer_than(time_to_wait) { run_build('testnode01') }
    end

    it 'renders pxelinux twice with firstboot switched if node builds' do
      expect_renders(
        "#{metal_config.repo_path}/pxelinux/default",
        to: '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
      ).once.ordered
      expect_renders(
        "#{metal_config.repo_path}/pxelinux/default",
        to: '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
      ).once.ordered

      run_build('testnode01')
    end

    context "when 'basic' build method used" do
      before :each do
        allow_any_instance_of(Metalware::Namespaces::Node).to \
          receive(:build_method).and_return(Metalware::BuildMethods::Basic)
      end

      # Note: similar (but simpler) version of test for Kickstart build method.
      it 'specifies correct template dependencies' do
        build_command = run_build('testnode01')

        # Not ideal to test private method, but seems best way in this case.
        dependency_hash = build_command.send(:dependency_hash)

        expect(dependency_hash[:repo]).to eq(['basic/default'])
      end
    end
  end

  context 'when called for group' do
    # Creates the test Group Namespace
    before :each do
      groups = Metalware::Namespaces::MetalArray.new(
        [Metalware::Namespaces::Group.new(alces, 'testnodes', index: 1)]
      )
      allow(alces).to receive(:groups).and_return(groups)
    end

    it 'renders standard templates for each node' do
      expect_renders(
        "#{metal_config.repo_path}/pxelinux/default",
        to: '/var/lib/tftpboot/pxelinux.cfg/testnode01_HEX_IP'
      )

      expect_renders(
        "#{metal_config.repo_path}/pxelinux/default",
        to: '/var/lib/tftpboot/pxelinux.cfg/testnode02_HEX_IP'
      )

      run_build('testnodes', group: true)
    end
  end
end
