
# frozen_string_literal: true

require 'network'

RSpec.describe Metalware::Network do
  describe '#valid_interface?' do
    before :each do
      expect(NetworkInterface).to receive(:interfaces).and_return(
        ['eth0', 'eth1']
      )
    end

    it 'returns true for interface name in list of interfaces' do
      expect(described_class.valid_interface?('eth1')).to be true
    end

    it 'returns false for interface name not in list of interfaces' do
      expect(described_class.valid_interface?('eth3')).to be false
    end
  end
end
