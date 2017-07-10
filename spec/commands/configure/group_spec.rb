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

require 'spec_utils'
require 'validator/configure'

RSpec.describe Metalware::Commands::Configure::Group do
  def run_configure_group(group)
    SpecUtils.run_command(
      Metalware::Commands::Configure::Group, group
    )
  end

  # XXX extract this
  def create_directory_hierarchy
    FileUtils.mkdir_p Metalware::Constants::METALWARE_CONFIGS_PATH
    FileUtils.touch Metalware::Constants::DEFAULT_CONFIG_PATH

    FileUtils.mkdir_p Metalware::Constants::CACHE_PATH
    FileUtils.mkdir_p File.join(config.answer_files_path, 'groups')

    FileUtils.mkdir_p config.repo_path
    File.write config.configure_file, YAML.dump({
      questions: {},
      domain: {},
      group: {},
      node: {},
    })
  end

  let :config { Metalware::Config.new }
  let :groups_file {
    File.join(Metalware::Constants::CACHE_PATH, 'groups.yaml' )
  }
  let :groups_yaml { YAML.load_file(groups_file) }
  let :primary_groups { groups_yaml[:primary_groups] }

  before :each {
    allow(Metalware::Validator::Configure).to \
        receive(:new).and_return(OpenStruct.new({valid?: true}))
  }

  context 'when `cache/groups.yaml` does not exist' do
    it 'creates it and inserts new primary group' do
      FakeFSHelper.new(config).run do
        create_directory_hierarchy
        run_configure_group 'testnodes'

        expect(primary_groups).to eq [
          'testnodes'
        ]
      end
    end
  end


  context 'when `cache/groups.yaml` exists' do
    it 'inserts primary group if new' do
      FakeFSHelper.new(config).run do
        create_directory_hierarchy
        File.write groups_file, YAML.dump({
          primary_groups: [
            'first_group',
          ]
        })

        run_configure_group 'second_group'

        expect(primary_groups).to eq [
          'first_group',
          'second_group',
        ]
      end

    end

    it 'does nothing if primary group already presnt' do
      FakeFSHelper.new(config).run do
        create_directory_hierarchy
        File.write groups_file, YAML.dump({
          primary_groups: [
            'first_group',
            'second_group',
          ]
        })

        run_configure_group 'second_group'

        expect(primary_groups).to eq [
          'first_group',
          'second_group',
        ]
      end

    end
  end
end
