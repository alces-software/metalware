# frozen_string_literal: true

require 'file_path'

RSpec.describe Metalware::FilePath do
  describe 'asset files' do
    let(:file_path) { described_class }

    it 'defines an asset template' do
      path = File.join(file_path.repo, 'assets', 'rack.yaml')
      expect(file_path.asset_template('rack')).to eq(path)
    end

    it 'defines an asset final save path' do
      path = File.join(file_path.metalware_data, 'assets', 'rack01.yaml')
      expect(file_path.asset('rack01')).to eq(path)
    end
  end
end
