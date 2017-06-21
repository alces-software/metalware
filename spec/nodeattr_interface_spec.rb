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
        Metalware::NodeattrInterface.nodes_in_group('all')
      ).to eq(['login1', 'testnode01', 'testnode02', 'testnode03'])
    end

    it 'raises if cannot find gender group' do
      expect {
        Metalware::NodeattrInterface.nodes_in_group('non_existent')
      }.to raise_error Metalware::NoGenderGroupError
    end
  end

  describe '#groups_for_node' do
    it 'returns groups for given node, ordered as in genders' do
      testnode_groups = ['testnodes', 'nodes', 'cluster', 'all']
      expect(
        Metalware::NodeattrInterface.groups_for_node('testnode01')
      ).to eq(testnode_groups)
      expect(
        Metalware::NodeattrInterface.groups_for_node('testnode02')
      ).to eq(['pregroup'] + testnode_groups + ['postgroup'])
    end

    it 'raises if cannot find node' do
      expect {
        Metalware::NodeattrInterface.groups_for_node('non_existent')
      }.to raise_error Metalware::NodeNotInGendersError
    end
  end
end
