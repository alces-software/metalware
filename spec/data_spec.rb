
require 'data'


RSpec.describe Metalware::Data do
  let :data_file_path { '/home/some_data.yaml' }

  let :string_keyed_data {{
      'a_key' => 'foo',
      'another_key' => {
        'nested' => 'bar',
      },
  }}

  let :symbol_keyed_data {{
    a_key: 'foo',
    another_key: {
      nested: 'bar',
    }
  }}

  describe '#load' do
    subject { Metalware::Data.load(data_file_path) }

    it 'loads the data file and recursively converts all keys to symbols' do
      FileSystem.test do
        File.write(data_file_path, YAML.dump(string_keyed_data))

        expect(subject).to eq(symbol_keyed_data)
      end
    end

    it 'returns {} if the file is empty' do
      FileSystem.test do
        FileUtils.touch(data_file_path)

        expect(subject).to eq({})
      end
    end

    it 'returns {} if the file does not exist' do
      FileSystem.test do
        expect(subject).to eq({})
      end
    end

    it 'raises if the file contains invalid YAML' do
      FileSystem.test do
        File.write(data_file_path, '[half an array')

        expect { subject }.to raise_error Psych::SyntaxError
      end
    end
  end

  describe '#dump' do
    it 'dumps the data to the data file with all keys as strings' do
      FileSystem.test do
        Metalware::Data.dump(data_file_path, symbol_keyed_data)

        expect(
          YAML.load_file(data_file_path)
        ).to eq(string_keyed_data)
      end
    end
  end
end
