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

      context 'when $EDITOR is set' do
        let :editor { 'EDITOR-ENV-VAR' }
        before :each { ENV['EDITOR'] = editor }

        it 'uses the $EDITOR env var' do
          expect(subject.editor).to eq(editor)
        end

        context 'when $VISUAL is set' do
          let :visual { 'VISUAL-ENV-VAR' }
          before :each { ENV['VISUAL'] = visual }

          it 'uses the $VISUAL env var' do
            expect(subject.editor).to eq(visual)
          end
        end
      end
    end
  end
end
