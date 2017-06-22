
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
        Metalware::NodeattrInterface.nodes_in_group('domain')
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
      testnode_groups = ['testnodes', 'nodes', 'cluster', 'domain']
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
