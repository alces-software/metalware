# frozen_string_literal: true

RSpec.shared_examples 'record add command' do
  # Stops the editor from running the bash command
  before { allow(Metalware::Utils::Editor).to receive(:open) }

  it 'errors if the type does not exist' do
    expect do
      Metalware::Utils.run_command(described_class,
                                   'missing-type',
                                   'record-name',
                                   stderr: StringIO.new)
    end.to raise_error(Metalware::InvalidInput)
  end

  context 'when using the rack type' do
    before { FileSystem.root_setup(&:with_asset_types) }

    let(:type) { 'rack' }
    let(:saved_record_name) { 'saved-record' }

    let(:type_path) { Metalware::FilePath.asset_type(type) }

    def run_command(record_name = saved_record_name)
      Metalware::Utils.run_command(described_class,
                                   type,
                                   record_name,
                                   stderr: StringIO.new)
    end

    it 'calls for the record to be opened and copied' do
      expect(Metalware::Utils::Editor).to receive(:open_copy)
        .with(type_path, record_path)
      run_command
    end

    it 'errors if the record already exists' do
      run_command
      expect do
        run_command
      end.to raise_error(Metalware::InvalidInput)
        .with_message(/already exists/)
    end

    it 'errors if the record name is an asset type' do
      expect do
        run_command(type)
      end.to raise_error(Metalware::InvalidInput)
        .with_message(/is not a valid/)
    end
  end
end
