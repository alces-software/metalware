# frozen_string_literal: true

require 'utils/editor'

RSpec.describe Metalware::Utils::Editor do
  let(:default_editor) { described_class::DEFAULT_EDITOR }

  before { allow_any_instance_of(HighLine).to receive(:agree) }

  context 'with the environment variables unset' do
    before do |_example|
      ENV.delete('VISUAL')
      ENV.delete('EDITOR')
    end

    describe '#editor' do
      it 'uses the default editor' do
        expect(described_class.editor).to eq(default_editor)
      end

      context 'when $EDITOR is set' do
        let(:editor) { 'EDITOR-ENV-VAR' }

        before { ENV['EDITOR'] = editor }

        it 'uses the $EDITOR env var' do
          expect(described_class.editor).to eq(editor)
        end

        context 'when $VISUAL is set' do
          let(:visual) { 'VISUAL-ENV-VAR' }

          before { ENV['VISUAL'] = visual }

          it 'uses the $VISUAL env var' do
            expect(described_class.editor).to eq(visual)
          end
        end
      end
    end

    describe '#open' do
      let(:file) { '/tmp/some-random-file' }

      it 'opens the file in the default editor' do
        cmd = "#{default_editor} #{file}"
        expect(Metalware::SystemCommand).to receive(:no_capture).with(cmd)
        thr = Thread.new { described_class.open(file) }
        sleep 0.1
        thr.kill
        sleep 0.001 while thr.alive?
      end
    end

    describe '#open_copy' do
      let(:source) { '/var/source-file.yaml' }
      let(:destination) { '/var/destination-file.yaml' }
      let(:initial_content) { { key: 'value' } }

      before do
        allow(described_class).to receive(:open)
        Metalware::Data.dump(source, initial_content)
      end

      def run_open_copy(&validation)
        described_class.open_copy(source, destination, &validation)
      end

      it 'creates and opens the temp file' do
        expect(described_class).to receive(:open).once.with(/\A\/tmp\//)
        run_open_copy
      end

      it 'saves the content to the destination' do
        expect(described_class).to receive(:open)
        run_open_copy
        expect(Metalware::Data.load(destination)).to eq(initial_content)
      end

      context 'with a validation block' do
        it 'calls the validation block' do
          expect do |b|
            # As the yield, 'b', does not return a value, the validation
            # will fail and needs to be caught
            expect do
              run_open_copy(&b)
            end.to raise_error(Metalware::ValidationFailure)
          end.to yield_control
        end

        it 'passes the temp file into the validation block' do
          run_open_copy do |path|
            content = Metalware::Data.load(path)
            expect(path).not_to match(source)
            expect(path).not_to match(destination)
            expect(content).to eq(initial_content)
          end
        end

        it 'saves the file if the validation passes' do
          run_open_copy { |_path| true }
          content = Metalware::Data.load(destination)
          expect(content).to eq(initial_content)
        end

        it 'errors if the validation fails' do
          expect do
            run_open_copy { |_path| false }
          end.to raise_error(Metalware::ValidationFailure)
        end
      end
    end
  end
end
