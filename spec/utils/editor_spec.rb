# frozen_string_literal: true

require 'utils/editor'

RSpec.describe Metalware::Utils::Editor do
  subject { Metalware::Utils::Editor }

  context 'with the environment variables unset' do
    before :each do |example|
      ENV.delete('VISUAL')
      ENV.delete('EDITOR')
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

    describe '#open' do
      after :each do
        Thread.list.each { |t| t.kill unless t == Thread.current }
      end

      let :file { '/tmp/some-random-file' }

      it 'opens the file in vi' do
        vi_cmd = "vi #{file}"
        expect(Metalware::SystemCommand).to \
          receive(:run).with(vi_cmd).and_call_original
        thr = Thread.new { subject.open(file) }
        sleep 0.1
        expect(thr).to be_alive
        expect(`ps | grep vi`).to include('vi')
        thr.kill
        sleep 0.001 while thr.alive?
      end

      it 'detects when the editor has ended' do
        thr = Thread.new { subject.open(file) }
        sleep 0.1
        pid = `ps | grep vi`.split[0]
        expect(pid).to match(/\d+/)
        expect do
          Process.kill(9, pid.to_i)
          Timeout::timeout(2) { sleep 0.001 while thr.alive? }
        end.not_to raise_error
      end
    end
  end
end

