
# frozen_string_literal: true

require 'managed_file'

RSpec.describe Metalware::ManagedFile do
  describe '#content' do
    let :managed_file { Tempfile.new }
    let :rendered_content { 'content' }

    RSpec.shared_examples 'includes managed file markers' do |comment_char|
      marker_comment_regex = /#{comment_char}{3,}/

      it "includes start marker with `#{comment_char}` as comment character" do
        expect(subject).to match(
          /#{marker_comment_regex} METALWARE_START #{marker_comment_regex}/
        )
      end

      it "includes end marker with `#{comment_char}` as comment character" do
        expect(subject).to match(
          /#{marker_comment_regex} METALWARE_END #{marker_comment_regex}/
        )
      end

      it "includes managed file info with `#{comment_char}` as comment character" do
        expect(subject).to include(
          "#{comment_char} This section of this file is managed by Alces Metalware"
        )
      end
    end

    context 'when no `comment_char` option passed' do
      subject do
        described_class.content(managed_file, rendered_content)
      end

      it_behaves_like 'includes managed file markers', '#'
    end

    context "when `comment_char: ';'` option passed" do
      subject do
        described_class.content(
          managed_file,
          rendered_content,
          comment_char: ';'
        )
      end

      it_behaves_like 'includes managed file markers', ';'
    end
  end
end
