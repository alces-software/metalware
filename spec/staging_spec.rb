
# frozen_string_literal: true

require 'staging'
require 'alces_utils'

module Metalware
  module Testing
    class GoodValidation
      def validate(_content)
        true
      end
    end

    class BadValidation
      def validate(_content)
        false
      end
    end
  end
end

RSpec.describe Metalware::Staging do
  include AlcesUtils

  def manifest
    Metalware::Staging.manifest(metal_config)
  end

  def update(&b)
    Metalware::Staging.update(metal_config, &b)
  end

  it 'loads a blank file list if the manifest is missing' do
    expect(manifest.files).to be_a(Array)
    expect(manifest.files).to be_empty
  end

  describe '#push_file' do
    let :test_content { 'I am a test file' }
    let :test_sync { '/etc/some-random-location' }
    let :test_staging { File.join('/var/lib/metalware/staging', test_sync) }

    before :each do
      update { |staging| staging.push_file(test_sync, test_content) }
    end

    it 'writes the file to the correct location' do
      expect(File.exist?(test_staging)).to eq(true)
    end

    it 'writes the correct content' do
      expect(File.read(test_staging)).to eq(test_content)
    end

    it 'saves the default options' do
      expect(manifest.files.first.managed).to eq(false)
      expect(manifest.files.first.validator).to eq(nil)
    end

    it 'updates the manifest' do
      expect(manifest.files.first.staging).to eq(test_staging)
      expect(manifest.files.first.sync).to eq(test_sync)
    end

    it 'can push more files' do
      update do |staging|
        staging.push_file('second', '')
        staging.push_file('third', '')
      end
      expect(manifest.files.length).to eq(3)
      expect(manifest.files[1].staging).to eq(file_path.staging('second'))
      expect(manifest.files[2].staging).to eq(file_path.staging('third'))
    end

    it 'saves the additional options' do
      update do |staging|
        staging.push_file('other', '', managed: true, validator: 'validate')
      end

      expect(manifest.files.last.managed).to eq(true)
      expect(manifest.files.last.validator).to eq('validate')
    end
  end

  describe '#sync_files' do
    let :files { ['first', 'second', 'third'].map { |f| "/tmp/#{f}" } }
    let :validate_file { '/tmp/validate-file' }

    before :each do
      Metalware::Staging.update(metal_config) do |staging|
        good_validator = Metalware::Testing::GoodValidation
        staging.push_file(validate_file, '', validator: good_validator)
        files.each { |f| staging.push_file(f, '') }
      end
    end

    context 'with valid files (aka no errors expected)' do
      before :each { Metalware::Staging.update(metal_config, &:sync_files) }

      it 'moves the files into place' do
        files.each { |f| expect(File.exist?(f)).to eq(true) }
      end

      it 'leaves the file list empty' do
        expect(manifest.files).to be_empty
      end

      it 'leaves the staging directory empty' do
        files = Dir[File.join(file_path.staging_dir, '**/*')].reject do |p|
          File.directory?(p)
        end
        expect(files).to be_empty
      end

      it 'moves the validated file into place' do
        expect(File.exist?(validate_file)).to eq(true)
      end
    end

    context 'with a validation error' do
      let :bad_file { '/tmp/bad-validator-file' }
      let :stderr { StringIO.new }

      before :each do
        Metalware::Staging.update(metal_config) do |staging|
          bad_validator = Metalware::Testing::BadValidation
          staging.push_file(bad_file, '', validator: bad_validator)
        end
        old_stderr = $stderr
        $stderr = stderr
        Metalware::Staging.update(metal_config, &:sync_files)
        $stderr = old_stderr
      end

      it "isn't removed from the manifest" do
        expect(manifest.files.length).to eq(1)
        expect(manifest.files.first.sync).to eq(bad_file)
      end

      it 'issues a validation failure error message' do
        stderr.rewind
        expect(stderr.read).to include('ValidationFailure')
      end
    end
  end
end
