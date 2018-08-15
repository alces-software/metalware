
# frozen_string_literal: true

require 'staging'
require 'alces_utils'

RSpec.describe Metalware::Staging do
  include AlcesUtils

  def manifest
    Metalware::Staging.manifest
  end

  def update(&b)
    Metalware::Staging.update(&b)
  end

  it 'loads a blank file list if the manifest is missing' do
    expect(manifest[:files]).to be_a(Hash)
    expect(manifest[:files]).to be_empty
  end

  describe '#push_file' do
    let(:test_content) { 'I am a test file' }
    let(:test_sync) { '/etc/some-random-location' }
    let(:test_staging) { File.join('/var/lib/metalware/staging', test_sync) }

    before do
      update { |staging| staging.push_file(test_sync, test_content) }
    end

    it 'writes the file to the correct location' do
      expect(File.exist?(test_staging)).to eq(true)
    end

    it 'writes the correct content' do
      expect(File.read(test_staging)).to eq(test_content)
    end

    it 'saves the default options' do
      expect(manifest[:files].first[1][:managed]).to eq(false)
      expect(manifest[:files].first[1][:validator]).to eq(nil)
    end

    it 'updates the manifest' do
      expect(manifest[:files][test_sync]).not_to be_empty
    end

    it 'can push more files' do
      update do |staging|
        staging.push_file('second', '')
        staging.push_file('third', '')
      end
      keys = manifest[:files].keys
      expect(manifest[:files].length).to eq(3)
      expect(keys[1]).to eq('second')
      expect(keys[2]).to eq('third')
    end

    it 'saves the additional options' do
      update do |staging|
        staging.push_file('other', '', managed: true, validator: 'validate')
      end
      key = manifest[:files].keys.last
      expect(manifest[:files][key][:managed]).to eq(true)
      expect(manifest[:files][key][:validator]).to eq('validate')
    end
  end

  describe '#delete_file_if' do
    let(:files) { ['first', 'second', 'third'].map { |f| "/tmp/#{f}" } }

    before do
      described_class.update do |staging|
        files.each { |f| staging.push_file(f, '') }
      end
    end

    def run_delete_files(&b)
      Metalware::Staging.update do |staging|
        staging.delete_file_if(&b)
      end
    end

    it 'deletes the files if the block returns true' do
      run_delete_files { |_file| true }
      expect(manifest[:files].keys.length).to eq(0)
      files.each { |path| expect(File.exist?(path)).to eq(false) }
    end

    it 'leaves the files in place' do
      run_delete_files { |_file| false }
      expect(manifest[:files].keys.length).to eq(files.length)
      files.map { |path| Metalware::FilePath.staging(path) }
           .each { |path| expect(File.exist?(path)).to eq(true) }
    end

    it 'can delete a single file' do
      run_delete_files { |file| file.sync.include?('second') }
      expect(manifest[:files].length).to eq(files.length - 1)
      expect(manifest[:files].keys.first).to include('first')
      expect(manifest[:files].keys.last).to include('third')
    end

    it 'files are not deleted if there is an error' do
      run_delete_files { |_f| raise 'test error' }
      expect(manifest[:files].length).to eq(files.length)
    end

    context 'with a managed file' do
      let(:managed_file) { '/tmp/managed' }
      let(:managed_content) { 'Managed Content' }

      def read_managed_content(file = managed_file)
        File.read(file).gsub(/^$\n/, '').split("\n")
      end

      RSpec.shared_examples 'writes managed file' do |comment_char|
        before do
          described_class.update do |staging|
            staging.push_file(
              managed_file,
              managed_content,
              managed: true,
              **additional_options
            )
            staging.delete_file_if do |file|
              File.write file.sync, file.content
            end
          end
        end

        expected_start_marker = [
          comment_char,
          Metalware::ManagedFile::MANAGED_START_MARKER,
          comment_char,
        ].join(' ')

        expected_end_marker = [
          comment_char,
          Metalware::ManagedFile::MANAGED_END_MARKER,
          comment_char,
        ].join(' ')

        it "writes the managed file content with `#{comment_char}` as comment char" do
          content = read_managed_content
          expect(content.first).to include(expected_start_marker)
          expect(content.last).to include(expected_end_marker)
          expect(content).to include(managed_content)
        end

        it 'preserves the start and end of the file and updates content' do
          file_start = 'FILE START'
          file_end = 'FILE END'
          start_content = [
            file_start,
            File.read(managed_file),
            file_end,
          ].join("\n")
          File.write(managed_file, start_content)

          new_content = 'NEW CONTENT'
          described_class.update do |staging|
            staging.push_file(
              managed_file,
              new_content,
              managed: true,
              **additional_options
            )

            staging.delete_file_if do |file|
              expect(file.content.first).to eq(file_start)
              expect(file.content.last).to eq(file_end)
              expect(file.content).to include(new_content)
              expect(file.content).not_to include(managed_content)
            end
          end
        end
      end

      context 'when no additional options set for file' do
        let(:additional_options) { {} }

        it_behaves_like 'writes managed file', '#'
      end

      context "when `comment_char: ';'` option set for file" do
        let(:additional_options) do
          { comment_char: ';' }
        end

        it_behaves_like 'writes managed file', ';'
      end
    end
  end
end
