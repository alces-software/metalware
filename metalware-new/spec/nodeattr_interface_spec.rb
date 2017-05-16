
require 'nodeattr_interface'
require 'spec_utils'


describe Metalware::NodeattrInterface do
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
  end
end
