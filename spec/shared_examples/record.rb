# frozen_string_literal: true

require 'spec_utils'

RSpec.shared_examples 'record' do |file_path_proc|
  let(:record_hash) do
    {
      pdus: ['pdu1', 'pdu2'],
      racks: ['rack1', 'rack2'],
    }
  end

  let(:legacy_records) { ['legacy1', 'legacy2'] }

  let(:records) do
    record_hash.reduce(legacy_records) do |memo, (_k, name)|
      memo.dup.concat(name)
    end
  end

  # Creates the record files
  before do
    paths = []
    record_hash.each do |types_dir, names|
      names.each do |name|
        paths << file_path_proc.call(types_dir.to_s, name)
      end
    end
    legacy_records.each do |legacy|
      paths << File.expand_path(file_path_proc.call('.', legacy))
    end
    paths.each do |path|
      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.touch(path)
    end
  end

  describe '#path' do
    it 'can not find a legacy records' do
      expect(described_class.path(legacy_records.last)).to eq(nil)
    end

    context 'with an record within a type directory' do
      let(:types_dir) { record_hash.keys.last }
      let(:name) { record_hash[types_dir].last }
      let(:expected_path) do
        file_path_proc.call(types_dir.to_s, name)
      end

      it 'finds the record' do
        expect(described_class.path(name)).to eq(expected_path)
      end

      it 'finds the record with the missing_error flag' do
        path = described_class.path(name, missing_error: true)
        expect(path).to eq(expected_path)
      end
    end

    context 'with a missing record' do
      let(:missing) { 'missing-record' }

      it 'returns nil by default' do
        expect(described_class.path(missing)).to eq(nil)
      end

      it 'errors with the missing_error flag' do
        expect do
          described_class.path(missing, missing_error: true)
        end.to raise_error(Metalware::MissingRecordError)
      end
    end
  end

  describe '#available?' do
    it 'returns true if the record is missing' do
      expect(described_class.available?('missing-record')).to eq(true)
    end

    it 'returns false if the record exists' do
      name = record_hash.values.last.last
      expect(described_class.available?(name)).to eq(false)
    end

    { 'public' => 'each', 'private' => 'alces' }.each do |type, method|
      it "returns false for #{type} methods on AssetArray" do
        expect(described_class.available?(method)).to eq(false)
      end
    end

    context 'when using a reserved type name' do
      let(:type) { 'rack' }

      it 'returns false' do
        expect(described_class.available?(type)).to eq(false)
      end

      it 'is false for the plural' do
        expect(described_class.available?(type.pluralize)).to eq(false)
      end

      # File paths will break how the type is worked out
      it 'is false for file paths' do
        expect(described_class.available?('some/path')).to eq(false)
      end
    end
  end

  describe '#type_from_path' do
    let(:type) { 'rack' }

    it 'errors if given a path not matching record_dir' do
      expect do
        described_class.type_from_path(invalid_path)
      end.to raise_error(Metalware::InvalidInput)
    end

    it 'returns the correct type' do
      expect(described_class.type_from_path(valid_path))
        .to eq(type)
    end
  end
end
