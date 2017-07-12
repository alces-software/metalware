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

require 'commands/hosts'
require 'templater'
require 'spec_utils'
require 'config'

RSpec.describe Metalware::Commands::Hosts do

  let :config { Metalware::Config.new }

  def run_hosts(node_identifier, **options_hash)
    # Adds default
    options_hash[:template] = "default" unless options_hash.key?(:template)

    SpecUtils.run_command(
      Metalware::Commands::Hosts, node_identifier, **options_hash
    )
  end

  before :each do
    SpecUtils.use_mock_genders(self)
    SpecUtils.use_unit_test_config(self)
    SpecUtils.use_mock_dependencies(self)
  end

  context 'when called without group argument' do
    it 'appends to hosts file by default' do
      expect(Metalware::Templater).to receive(:render_and_append_to_file).with(
        instance_of(Metalware::Config),
        "#{config.repo_path}/hosts/default",
        '/etc/hosts',
        hash_including(nodename: 'testnode01')
      )

      run_hosts('testnode01')
    end

    it 'uses a different template if template option passed' do
      expect(Metalware::Templater).to receive(:render_and_append_to_file).with(
        instance_of(Metalware::Config),
        "#{config.repo_path}/hosts/my_template",
        '/etc/hosts',
        hash_including(nodename: 'testnode01')
      )

      run_hosts('testnode01', template: 'my_template')
    end

    context 'when dry-run' do
      it 'outputs what would be appended' do
        expect(Metalware::Templater).to receive(:render_to_stdout).with(
          instance_of(Metalware::Config),
          "#{config.repo_path}/hosts/default",
          hash_including(nodename: 'testnode01')
        )

        run_hosts('testnode01', dry_run: true)
      end
    end
  end

  context 'when called for group' do
    let :group_parameters {
      [
        hash_including(nodename: 'testnode01'),
        hash_including(nodename: 'testnode02'),
        hash_including(nodename: 'testnode03')
      ]
    }

    it 'appends to hosts file by default' do
      group_parameters.each do |parameters|
        expect(Metalware::Templater).to receive(:render_and_append_to_file).with(
          instance_of(Metalware::Config),
          "#{config.repo_path}/hosts/default",
          '/etc/hosts',
          parameters
        ).ordered
      end

      run_hosts('testnodes', group: true)
    end

    context 'when dry-run' do
      it 'outputs what would be appended' do
      group_parameters.each do |parameters|
        expect(Metalware::Templater).to receive(:render_to_stdout).with(
          instance_of(Metalware::Config),
          "#{config.repo_path}/hosts/default",
          parameters
        ).ordered
      end

        run_hosts('testnodes', group: true, dry_run: true)
      end
    end
  end
end
