
require 'defaults'


RSpec.describe Metalware::Defaults do
  describe '#method_missing' do
    it 'provides the correct default values' do
      expect(Metalware::Defaults.hosts.template).to eq('default')
      expect(Metalware::Defaults.build.kickstart).to eq('default')
    end

    it 'returns nil for not present option' do
      expect(Metalware::Defaults.hosts.foo).to be(nil)
    end
  end
end
