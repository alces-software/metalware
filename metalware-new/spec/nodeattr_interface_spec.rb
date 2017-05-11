
require 'nodeattr_interface'

GENDERS_FILE = File.join(FIXTURES_PATH, 'genders')

describe Metalware::NodeattrInterface do
  before do
    stub_const("Metalware::Constants::NODEATTR_COMMAND", "nodeattr -f #{GENDERS_FILE}")
  end

  describe '#nodes_in_group' do
    it 'returns names of all nodes in the given gender group' do
      expect(
        Metalware::NodeattrInterface.nodes_in_group('masters')
      ).to eq(['login1'])
      expect(
        Metalware::NodeattrInterface.nodes_in_group('nodes')
      ).to eq(['node01', 'node02', 'node03'])
      expect(
        Metalware::NodeattrInterface.nodes_in_group('all')
      ).to eq(['login1', 'node01', 'node02', 'node03'])
    end
  end
end
