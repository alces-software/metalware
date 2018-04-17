# frozen_string_literal: true

require 'commands'
require 'utils'
require 'alces_utils'
require 'active_support/core_ext/module/delegation'

module Metalware
  module Testing
    class GoodValidation
      def self.validate(_content)
        true
      end
    end

    class BadValidation
      def self.validate(_content)
        false
      end
    end
  end
end

RSpec.describe Metalware::Commands::Sync do
  include AlcesUtils

  def run_sync
    Metalware::Utils.run_command(Metalware::Commands::Sync)
  end

  delegate :manifest, to: Metalware::Staging

  describe '#sync_files' do
    let(:files) { ['first', 'second', 'third'].map { |f| "/tmp/#{f}" } }
    let(:validate_file) { '/tmp/validate-file' }

    before do
      Metalware::Staging.update do |staging|
        good_validator = Metalware::Testing::GoodValidation.to_s
        staging.push_file(validate_file, '', validator: good_validator)
        files.each { |f| staging.push_file(f, '') }
      end
    end

    context 'with valid files (aka no errors expected)' do
      before { run_sync }

      it 'moves the files into place' do
        files.each { |f| expect(File.exist?(f)).to eq(true) }
      end

      it 'moves the validated file into place' do
        expect(File.exist?(validate_file)).to eq(true)
      end
    end

    context 'with a validation error' do
      let(:bad_file) { '/tmp/bad-validator-file' }
      let(:stderr) { StringIO.new }

      before do
        # Allows the error to be printed
        allow(Metalware::Output).to \
          (receive(:stderr).and_wrap_original { |_m, *arg| warn arg })

        Metalware::Staging.update do |staging|
          bad_validator = Metalware::Testing::BadValidation.to_s
          staging.push_file(bad_file, '', validator: bad_validator)
        end
        old_stderr = $stderr
        $stderr = stderr
        run_sync
        $stderr = old_stderr
      end

      it "isn't removed from the manifest" do
        expect(manifest[:files].length).to eq(1)
        expect(manifest[:files].first[0]).to eq(bad_file)
      end

      it 'issues a validation failure error message' do
        stderr.rewind
        expect(stderr.read).to include('ValidationFailure')
      end
    end
  end
end
