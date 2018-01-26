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
  include AlcesUtils

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

  AlcesUtils.mock self, :each do
    mock_node('testnode01')
    config(alces.node, files: TEST_FILES_HASH)
  end

  subject do
    Metalware::BuildFilesRetriever.new(metal_config)
  end

  before do
    SpecUtils.use_mock_determine_hostip_script(self)
  end

  describe '#retrieve_for_node' do
    before :each do
      FileSystem.root_setup do |fs|
        fs.with_clone_fixture('configs/unit-test.yaml')
      end
      SpecUtils.use_unit_test_config(self)
      allow(Metalware::Input).to receive(:download)
    end

    context 'when everything works' do
      it 'returns the correct files object' do
        some_path = File.join(metal_config.repo_path, 'files/some/file_in_repo')
        FileUtils.mkdir_p File.dirname(some_path)
        FileUtils.touch(some_path)
        other_path = '/some/other/path'
        FileUtils.mkdir_p File.dirname(other_path)
        FileUtils.touch(other_path)
        url_path = '/var/lib/metalware/cache/templates/url'
        FileUtils.mkdir_p File.dirname(url_path)
        FileUtils.touch(url_path)

        retrieved_files = subject.retrieve_for_node(alces.node)

        expect(retrieved_files[:namespace01][0]).to eq(raw: 'some/file_in_repo',
                                                       name: 'file_in_repo',
                                                       template_path: some_path,
                                                       rendered_path: '/var/lib/metalware/rendered/testnode01/namespace01/file_in_repo',
                                                       url: 'http://1.2.3.4/metalware/testnode01/namespace01/file_in_repo')

        expect(retrieved_files[:namespace01][1]).to eq(raw: '/some/other/path',
                                                       name: 'path',
                                                       template_path: other_path,
                                                       rendered_path: '/var/lib/metalware/rendered/testnode01/namespace01/path',
                                                       url: 'http://1.2.3.4/metalware/testnode01/namespace01/path')

        expect(retrieved_files[:namespace01][2]).to eq(raw: 'http://example.com/url',
                                                       name: 'url',
                                                       template_path: url_path,
                                                       rendered_path: '/var/lib/metalware/rendered/testnode01/namespace01/url',
                                                       url: 'http://1.2.3.4/metalware/testnode01/namespace01/url')
      end

      it 'downloads any URL identifiers to cache' do
        expect(Metalware::Input).to receive(:download).with(
          'http://example.com/url',
          '/var/lib/metalware/cache/templates/url'
        )

        subject.retrieve_for_node(alces.node)
      end
    end

    context 'when template file path not present' do
      before :each do
        allow(File).to receive(:exist?).and_return(false)
      end

      describe 'for repo file identifier' do
        it 'adds error to file entry' do
          retrieved_files = subject.retrieve_for_node(alces.node)

          repo_file_entry = retrieved_files[:namespace01][0]
          template_path = "#{metal_config.repo_path}/files/some/file_in_repo"
          expect(repo_file_entry[:error]).to match(/#{template_path}.*does not exist/)

          # Does not make sense to have these keys if file does not exist.
          expect(repo_file_entry.key?(:template_path)).to be false
          expect(repo_file_entry.key?(:url)).to be false
        end
      end

      describe 'for absolute path file identifier' do
        it 'adds error to file entry' do
          retrieved_files = subject.retrieve_for_node(alces.node)

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
        retrieved_files = subject.retrieve_for_node(alces.node)

        url_file_entry = retrieved_files[:namespace01][2]
        url = 'http://example.com/url'
        expect(url_file_entry[:error]).to match(/#{url}.*#{@http_error}/)

        # Does not make sense to have these keys if file not retrievable.
        expect(url_file_entry.key?(:template_path)).to be false
        expect(url_file_entry.key?(:url)).to be false
      end
    end
  end

  describe '#retrieve_for_plugin' do
    let :plugin_name { 'some_plugin' }
    let :plugin_path { File.join(file_path.plugins_dir, plugin_name) }

    let :plugin do
      FileUtils.mkdir_p(plugin_path)
      Metalware::Plugins.all.find { |p| p.name == plugin_name }
    end

    before :each do
      FileSystem.root_setup do |fs|
        # This must exist so can attempt to get node groups.
        fs.touch Metalware::Constants::GENDERS_PATH
      end
    end

    it 'retrieves plugin files' do
      # Create plugin file
      plugin_files_dir = File.join(plugin_path, 'files/')
      plugin_file_name = 'some_file'
      plugin_file_path = File.join('path/to', plugin_file_name)
      absolute_plugin_file_path = File.join(plugin_files_dir, plugin_file_path)
      FileUtils.mkdir_p(File.dirname(absolute_plugin_file_path))
      FileUtils.touch absolute_plugin_file_path

      # Create plugin config specifying file.
      plugin_config_dir = File.join(plugin_path, 'config')
      FileUtils.mkdir_p(plugin_config_dir)
      Metalware::Data.dump(
        plugin.domain_config,
        {files: {some_section: [plugin_file_path]}}
      )

      plugin_namespace = Metalware::Namespaces::Plugin.new(plugin, node: alces.node)
      retrieved_files = subject.retrieve_for_plugin(plugin_namespace)

      relative_rendered_path = "testnode01/#{plugin_name}/some_section/#{plugin_file_name}"
      expect(retrieved_files).to eq({
        some_section: [{
          raw: plugin_file_path,
          name: plugin_file_name,
          template_path: absolute_plugin_file_path,
          rendered_path: "/var/lib/metalware/rendered/#{relative_rendered_path}",
          url: "http://1.2.3.4/metalware/#{relative_rendered_path}",
        }]
      })
    end
  end
end
