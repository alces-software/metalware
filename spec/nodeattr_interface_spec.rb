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

require 'nodeattr_interface'
require 'spec_utils'
require 'exceptions'

RSpec.describe Metalware::NodeattrInterface do
  context 'with setup1 genders' do
    before do
      SpecUtils.use_mock_genders(self, genders_file: 'setup1/genders')
    end

    describe '#nodes_in_primary_group' do
      it 'returns only the nodes in the primary group' do
        nodes = Metalware::NodeattrInterface.nodes_in_primary_group('group1')
        expect(nodes).to contain_exactly('nodeA01', 'nodeA02')
      end
    end
  end

  context 'using mock genders' do
    before do
      SpecUtils.use_mock_genders(self)
    end

    describe '#nodes_in_group' do
      it 'returns names of all nodes in the given gender group' do
        expect(
          Metalware::NodeattrInterface.nodes_in_group('masters')
        ).to eq(['login1'])
        expect(
          Metalware::NodeattrInterface.nodes_in_group('nodes')
        ).to eq(['testnode01', 'testnode02', 'testnode03'])
        expect(
          Metalware::NodeattrInterface.nodes_in_group('cluster')
        ).to eq(['login1', 'testnode01', 'testnode02', 'testnode03'])
      end

      it 'raises if cannot find gender group' do
        expect do
          Metalware::NodeattrInterface.nodes_in_group('non_existent')
        end.to raise_error Metalware::NoGenderGroupError
      end
    end

    describe '#groups_for_node' do
      it 'returns groups for given node, ordered as in genders' do
        testnode_groups = ['testnodes', 'nodes', 'cluster']
        expect(
          Metalware::NodeattrInterface.groups_for_node('testnode01')
        ).to eq(testnode_groups)
        expect(
          Metalware::NodeattrInterface.groups_for_node('testnode02')
        ).to eq(['pregroup'] + testnode_groups + ['postgroup'])
      end

      it 'raises if cannot find node' do
        expect do
          Metalware::NodeattrInterface.groups_for_node('non_existent')
        end.to raise_error Metalware::NodeNotInGendersError
      end
    end
  end

  describe '#validate_genders_file', real_fs: true do
    let :genders_file { Tempfile.new }
    let :genders_path { genders_file.path }

    subject do
      Metalware::NodeattrInterface.validate_genders_file(genders_path)
    end

    it 'returns true and no error when given a valid genders file' do
      File.write(genders_path, "node01 nodes,other,groups\n")

      expect(subject).to eq [true, '']
    end

    it 'returns false and the error when given an invalid genders file' do
      # This genders file is invalid as `node01` is given `nodes` group twice.
      File.write(genders_path, "node01 nodes,other,groups\nnode01 nodes\n")

      expect(subject.length).to be 2 # Sanity check.
      expect(subject.first).to be false
      expect(subject.last).to match(/duplicate attribute/)
    end

    it 'raises if given file does not exist' do
      # Get path to the test genders file and then delete it, so we have a path
      # to a file which almost certainly won't exist (barring some very
      # improbable race condition).
      path = genders_path
      genders_file.delete

      expect do
        Metalware::NodeattrInterface.validate_genders_file(path)
      end.to raise_error(Metalware::FileDoesNotExistError)
    end
  end
end
