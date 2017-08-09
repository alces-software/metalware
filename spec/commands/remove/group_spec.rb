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
require 'filesystem'
require 'commands/remove/group'
require 'nodeattr_interface'
require 'node'
require 'config'
require 'ostruct'
require 'validator/loader'
require 'spec_utils'

RSpec.describe Metalware::Commands::Remove::Group do
  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_minimal_repo
      fs.with_answer_fixtures('setup1/answers')
      fs.with_groups_cache_fixture('setup1/cache/groups.yaml')
    end
  end

  let :config { Metalware::Config.new }
  let :loader { Metalware::Validator::Loader.new(config) }
  let :cache { loader.groups_cache[:primary_groups] }

  let :initial_files { answer_files }
  let :deleted_files { initial_files - answer_files }

  before :each do
    SpecUtils.mock_validate_genders_success(self)
    SpecUtils.use_mock_genders(self, genders_file: 'setup1/genders')
    filesystem.test { initial_files }
  end

  def answer_files
    Dir[File.join(config.answer_files_path, '**/*.yaml')]
  end

  def expected_deleted_files(group)
    Metalware::NodeattrInterface.nodes_in_primary_group(group)
      .map { |node| "nodes/#{node}.yaml" }
      .unshift(["groups/#{group}.yaml"])
      .map { |f| File.join(config.answer_files_path, f) }
  end

  def test_remove_group(group)
    filesystem.test do |_fs|
      Metalware::Commands::Remove::Group.new([group], OpenStruct.new)
      expect(expected_deleted_files(group)).to include(*deleted_files)
      expect(answer_files).not_to include(*expected_deleted_files(group))
      expect(cache).not_to include(group)
      yield
    end
  end

  context 'with no other groups' do
    it 'removes group and node answer files' do
      test_remove_group('nodes') do
        other_node_groups = Metalware::Node.new(config, 'nodeB01').groups
        expect(other_node_groups).to include('group1', 'group2')
      end
    end
  end

  context 'with a primary group that is used as an additional group' do
    it 'remove the primary group without altering the other nodes' do
      test_remove_group('group1') do
        other_node_groups = Metalware::Node.new(config, 'nodeB01').groups
        expect(other_node_groups).to include('group1')
      end
    end
  end

  context 'with a nodes in an additional group (that is also primary)' do
    it 'does not remove the other additional(/primary) group' do
      test_remove_group('group2') do
        other_node_groups = Metalware::Node.new(config, 'nodeA01').groups
        expect(other_node_groups).to include('group1')
      end
    end
  end
end