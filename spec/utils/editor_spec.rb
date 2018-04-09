# frozen_string_literal: true

require 'utils/editor'

RSpec.describe Metalware::Utils::Editor do
  subject { Metalware::Utils::Editor }
  let :default_editor { subject::DEFAULT_EDITOR }

  context 'with the environment variables unset' do
    before :each do |example|
      ENV.delete('VISUAL')
      ENV.delete('EDITOR')
    end

    describe '#editor' do
      it 'uses the default editor' do
        expect(subject.editor).to eq(default_editor)
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
      let :file { '/tmp/some-random-file' }

      it 'opens the file in the default editor' do
        cmd = "#{default_editor} #{file}"
        expect(Metalware::SystemCommand).to receive(:no_capture).with(cmd)
        thr = Thread.new { subject.open(file) }
        sleep 0.1
        thr.kill
        sleep 0.001 while thr.alive?
      end
    end


    describe '#open_copy' do
      let :source { '/var/source-file.yaml' }
      let :destination { '/var/destination-file.yaml' }
      let :initial_content { { key: 'value' } }

      before :each { Metalware::Data.dump(source, initial_content) }

      it 'creates and opens the temp file' do
        expect(subject).to receive(:open).once.with(/\A\/tmp\//)
        subject.open_copy(source, destination)
      end

      it 'destination contains content' do
        expect(subject).to receive(:open)
        subject.open_copy(source, destination)
        expect(Metalware::Data.load(destination)).to eq(initial_content)
      end
    end
  end
end

