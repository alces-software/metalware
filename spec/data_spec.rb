
# frozen_string_literal: true

require 'data'
require 'filesystem'

RSpec.describe Metalware::Data do
  let :data_file_path { '/path/to/some_data.yaml' }

  let :string_keyed_data do
    {
      'a_key' => 'foo',
      'another_key' => {
        'nested' => 'bar',
      },
    }
  end

  let :symbol_keyed_data do
    {
      a_key: 'foo',
      another_key: {
        nested: 'bar',
      },
    }
  end

  let :filesystem do
    FileSystem.setup do |fs|
      fs.mkdir_p(File.dirname(data_file_path))
    end
  end

  describe '#load' do
    subject { Metalware::Data.load(data_file_path) }

    it 'loads the data file and recursively converts all keys to symbols' do
      filesystem.test do
        File.write(data_file_path, YAML.dump(string_keyed_data))

        expect(subject).to eq(symbol_keyed_data)
      end
    end

    it 'returns {} if the file is empty' do
      filesystem.test do
        FileUtils.touch(data_file_path)

        expect(subject).to eq({})
      end
    end

    it 'returns {} if the file does not exist' do
      filesystem.test do
        expect(subject).to eq({})
      end
    end

    it 'raises if the file contains invalid YAML' do
      filesystem.test do
        File.write(data_file_path, '[half an array')

        expect { subject }.to raise_error Psych::SyntaxError
      end
    end

    it 'raises if loaded file does not contain hash' do
      filesystem.test do
        array = ['foo', 'bar']
        File.write(data_file_path, YAML.dump(array))

        expect { subject }.to raise_error(Metalware::DataError)
      end
    end
  end

  describe '#dump' do
    it 'dumps the data to the data file with all keys as strings' do
      filesystem.test do
        Metalware::Data.dump(data_file_path, symbol_keyed_data)

        expect(
          YAML.load_file(data_file_path)
        ).to eq(string_keyed_data)
      end
    end

    it 'raises if attempt to dump non-hash data' do
      filesystem.test do
        expect do
          Metalware::Data.dump(data_file_path, ['foo', 'bar'])
        end.to raise_error(Metalware::DataError)
      end
    end
  end
end
