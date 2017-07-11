
require 'data'


RSpec.describe Metalware::Data do
  let :data_file_path { '/home/some_data.yaml' }
  let :some_data {{
      'a_key' => 'foo',
      'another_key' => 'bar',
  }}

  describe '#load' do
    subject { Metalware::Data.load(data_file_path) }

    it 'loads the data file' do
      FileSystem.test do
        File.write(data_file_path, YAML.dump(some_data))

        expect(subject).to eq(some_data)
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
    it 'dumps the data to the data file' do
      FileSystem.test do
        Metalware::Data.dump(data_file_path, some_data)

        expect(
          YAML.load_file(data_file_path)
        ).to eq(some_data)
      end
    end
  end
end
