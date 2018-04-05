require 'file_path'

RSpec.describe Metalware::FilePath do
  describe 'asset files' do
    let :file_path { Metalware::FilePath }

    it 'defines an asset template' do
      expect(file_path.asset_template('rack')).to eq('/var/lib/metalware/repo/assets/rack.yaml')
    end

    it 'defines an asset final save path' do
      expect(file_path.asset_final('rack01')).to eq('/var/lib/metalware/assets/rack01.yaml')
    end
  end
end
