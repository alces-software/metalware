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
require 'filesystem'

RSpec.describe Metalware::NodeattrInterface do
  include AlcesUtils

  context 'with setup1 genders' do
    before do
      FileSystem.root_setup do |fs|
        fs.with_genders_fixtures('setup1/genders')
      end
    end

    describe '#nodes_in_group' do
      it 'returns only the nodes in the primary group' do
        nodes = described_class.nodes_in_group('group1')
        expect(nodes).to contain_exactly('nodeA01', 'nodeA02')
      end
    end
  end

  context 'using mock genders' do
    before do
      FileSystem.root_setup(&:with_genders_fixtures)
    end

    describe '#nodes_in_gender' do
      it 'returns names of all nodes in the given gender group' do
        expect(
          described_class.nodes_in_gender('masters')
        ).to eq(['login1'])
        expect(
          described_class.nodes_in_gender('nodes')
        ).to eq(['testnode01', 'testnode02', 'testnode03'])
        expect(
          described_class.nodes_in_gender('cluster')
        ).to eq(['login1', 'testnode01', 'testnode02', 'testnode03'])
      end

      it 'raises if cannot find gender group' do
        expect do
          described_class.nodes_in_gender('non_existent')
        end.to raise_error Metalware::NoGenderGroupError
      end
    end

    describe '#genders_for_node' do
      it 'returns groups for given node, ordered as in genders' do
        testnode_groups = ['testnodes', 'nodes', 'cluster']
        expect(
          described_class.genders_for_node('testnode01')
        ).to eq(testnode_groups)
        expect(
          described_class.genders_for_node('testnode02')
        ).to eq(['pregroup'] + testnode_groups + ['postgroup'])
      end

      it 'raises if cannot find node' do
        expect do
          described_class.genders_for_node('non_existent')
        end.to raise_error Metalware::NodeNotInGendersError
      end
    end
  end

  describe '#validate_genders_file' do
    subject do
      described_class.validate_genders_file(genders_path)
    end

    let(:genders_file) { Tempfile.new }
    let(:genders_path) { genders_file.path }

    it 'returns true and no error when given a valid genders file' do
      File.write(genders_path, "node01 nodes,other,groups\n")

      expect(subject).to eq true
    end

    it 'raises an error if the genders file is invalid' do
      # This genders file is invalid as `node01` is given `nodes` group twice.
      File.write(genders_path, "node01 nodes,other,groups\nnode01 nodes\n")

      expect { subject }.to raise_error Metalware::SystemCommandError
    end

    it 'raises if given file does not exist' do
      # Get path to the test genders file and then delete it, so we have a path
      # to a file which almost certainly won't exist (barring some very
      # improbable race condition).
      path = genders_path
      genders_file.delete

      expect do
        described_class.validate_genders_file(path)
      end.to raise_error(Metalware::FileDoesNotExistError)
    end
  end
end
