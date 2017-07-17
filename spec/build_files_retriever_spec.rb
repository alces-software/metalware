# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

require 'build_files_retriever'
require 'input'
require 'spec_utils'
require 'config'

RSpec.describe Metalware::BuildFilesRetriever do
  TEST_FILES_HASH = {
    namespace01: [
      'some/file_in_repo',
      '/some/other/path',
      'http://example.com/url',
    ],
    namespace02: [
      'another_file',
    ],
  }.freeze

  let :config { Metalware::Config.new }

  before do
    SpecUtils.use_mock_determine_hostip_script(self)
    SpecUtils.use_unit_test_config(self)
  end

  describe '#retrieve' do
    before :each do
      allow(Metalware::Input).to receive(:download)
    end

    context 'when everything works' do
      before :each do
        allow(File).to receive(:exist?).and_return(true)
      end

      it 'returns the correct files object' do
        retriever = Metalware::BuildFilesRetriever.new('testnode01', Metalware::Config.new)
        retrieved_files = retriever.retrieve(TEST_FILES_HASH)

        expect(retrieved_files[:namespace01][0]).to eq(raw: 'some/file_in_repo',
                                                       name: 'file_in_repo',
                                                       template_path: File.join(config.repo_path, 'files/some/file_in_repo'),
                                                       url: 'http://1.2.3.4/metalware/testnode01/namespace01/file_in_repo')

        expect(retrieved_files[:namespace01][1]).to eq(raw: '/some/other/path',
                                                       name: 'path',
                                                       template_path: '/some/other/path',
                                                       url: 'http://1.2.3.4/metalware/testnode01/namespace01/path')

        expect(retrieved_files[:namespace01][2]).to eq(raw: 'http://example.com/url',
                                                       name: 'url',
                                                       template_path: '/var/lib/metalware/cache/templates/url',
                                                       url: 'http://1.2.3.4/metalware/testnode01/namespace01/url')
      end

      it 'downloads any URL identifiers to cache' do
        expect(Metalware::Input).to receive(:download).with(
          'http://example.com/url',
          '/var/lib/metalware/cache/templates/url'
        )

        retriever = Metalware::BuildFilesRetriever.new('testnode01', Metalware::Config.new)
        retriever.retrieve(TEST_FILES_HASH)
      end
    end

    context 'when template file path not present' do
      before :each do
        allow(File).to receive(:exist?).and_return(false)
      end

      describe 'for repo file identifier' do
        it 'adds error to file entry' do
          retriever = Metalware::BuildFilesRetriever.new('testnode01', Metalware::Config.new)
          retrieved_files = retriever.retrieve(TEST_FILES_HASH)

          repo_file_entry = retrieved_files[:namespace01][0]
          template_path = "#{config.repo_path}/files/some/file_in_repo"
          expect(repo_file_entry[:error]).to match(/#{template_path}.*does not exist/)

          # Does not make sense to have these keys if file does not exist.
          expect(repo_file_entry.key?(:template_path)).to be false
          expect(repo_file_entry.key?(:url)).to be false
        end
      end

      describe 'for absolute path file identifier' do
        it 'adds error to file entry' do
          retriever = Metalware::BuildFilesRetriever.new('testnode01', Metalware::Config.new)
          retrieved_files = retriever.retrieve(TEST_FILES_HASH)

          absolute_file_entry = retrieved_files[:namespace01][1]
          template_path = '/some/other/path'
          expect(absolute_file_entry[:error]).to match(/#{template_path}.*does not exist/)

          # Does not make sense to have these keys if file does not exist.
          expect(absolute_file_entry.key?(:template_path)).to be false
          expect(absolute_file_entry.key?(:url)).to be false
        end
      end
    end

    context 'when error retrieving URL file' do
      before :each do
        @http_error = SpecUtils.fake_download_error(self)
      end

      it 'adds error to file entry' do
        retriever = Metalware::BuildFilesRetriever.new('testnode01', Metalware::Config.new)
        retrieved_files = retriever.retrieve(TEST_FILES_HASH)

        url_file_entry = retrieved_files[:namespace01][2]
        url = 'http://example.com/url'
        expect(url_file_entry[:error]).to match(/#{url}.*#{@http_error}/)

        # Does not make sense to have these keys if file not retrievable.
        expect(url_file_entry.key?(:template_path)).to be false
        expect(url_file_entry.key?(:url)).to be false
      end
    end
  end
end
