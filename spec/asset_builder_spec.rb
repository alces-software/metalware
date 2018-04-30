# frozen_string_literal: true

require 'spec_utils'
require 'asset_builder'

RSpec.describe Metalware::AssetBuilder do
  subject { described_class.new }

  describe '#queue' do
    it 'initially returns an empty array' do
      expect(subject.queue).to eq([])
    end
  end
end
