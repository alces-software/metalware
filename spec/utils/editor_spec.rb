# frozen_string_literal: true

require 'utils/editor'

RSpec.describe Metalware::Utils::Editor do
  subject { Metalware::Utils::Editor }

  context 'with the environment variables unset' do
    before :each do |example|
      ENV['VISUAL'] = nil
      ENV['EDITOR'] = nil
    end

    describe '#editor' do
      it 'defaults to vi' do
        expect(subject.editor).to eq('vi')
      end
    end
  end
end
