# frozen_string_literal: true

require 'input'
require 'spec_utils'

RSpec.describe Metalware::BuildFilesRetrievers::Cache do
  include AlcesUtils

  subject { described_class.new }

  let(:test_node_name) { 'testnode01' }
  let(:test_node) { alces.nodes.find_by_name(test_node_name) }
  let(:data_path) { Metalware::FilePath.metalware_data }
  let(:test_url) { 'http://example.com/url' }
  let(:test_files_hash) do
    {
      namespace01: [
        'some/file_in_repo',
        '/some/other/path',
        test_url,
      ],
      namespace02: [
        'another_file',
      ],
    }
  end

  AlcesUtils.mock self, :each do
    config(mock_node(test_node_name), files: test_files_hash)
  end

  before do
    use_mock_determine_hostip_script
  end

  def hash_url(url)
    Digest::SHA1.hexdigest(url)
  end

  context 'when retrieving a nodes files' do
    before do
      FileSystem.root_setup do |fs|
        fs.with_clone_fixture('configs/unit-test.yaml')
      end
      use_unit_test_config
      allow(Metalware::Input).to receive(:download)
        .and_wrap_original do |_, _, to_path|
        FileUtils.touch(to_path)
      end
    end

    context 'when everything works' do
      it 'returns the correct files object' do
        file_path = '/rendered/testnode01/files/repo/namespace01/file_in_repo'
        some_path = File
                    .join(Metalware::FilePath.repo, 'files/some/file_in_repo')
        FileUtils.mkdir_p File.dirname(some_path)
        FileUtils.touch(some_path)
        other_path = '/some/other/path'
        FileUtils.mkdir_p File.dirname(other_path)
        FileUtils.touch(other_path)

        retrieved_files = subject.retrieve(test_node)

        expect(retrieved_files[:namespace01][0]).to eq(
          raw: 'some/file_in_repo',
          name: 'file_in_repo',
          template_path: some_path,
          rendered_path: data_path + file_path,
          url: 'http://1.2.3.4/metalware/testnode01/files/repo/namespace01/file_in_repo'
        )

        expect(retrieved_files[:namespace01][1]).to eq(
          raw: '/some/other/path',
          name: 'path',
          template_path: other_path,
          rendered_path: data_path +
            '/rendered/testnode01/files/repo/namespace01/path',
          url: 'http://1.2.3.4/metalware/testnode01/files/repo/namespace01/path'
        )

        expect(retrieved_files[:namespace01][2]).to eq(
          raw: test_url,
          name: 'url',
          template_path: '/var/lib/metalware/cache/templates/' +
            hash_url(test_url),
          rendered_path: data_path +
            '/rendered/testnode01/files/repo/namespace01/url',
          url: 'http://1.2.3.4/metalware/testnode01/files/repo/namespace01/url'
        )
      end

      it 'downloads any URL identifiers to cache' do
        expect(Metalware::Input).to receive(:download).with(
          test_url, data_path + '/cache/templates/' + hash_url(test_url)
        )

        subject.retrieve(test_node)
      end
    end

    context 'when template file path not present' do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      describe 'for repo file identifier' do
        it 'adds error to file entry' do
          retrieved_files = subject.retrieve(test_node)

          repo_file_entry = retrieved_files[:namespace01][0]
          template_path = "#{Metalware::FilePath.repo}/files/some/file_in_repo"
          expect(repo_file_entry[:error])
            .to match(/#{template_path}.*does not exist/)

          # Does not make sense to have these keys if file does not exist.
          expect(repo_file_entry.key?(:template_path)).to be false
          expect(repo_file_entry.key?(:url)).to be false
        end
      end

      describe 'for absolute path file identifier' do
        it 'adds error to file entry' do
          retrieved_files = subject.retrieve(test_node)

          absolute_file_entry = retrieved_files[:namespace01][1]
          template_path = '/some/other/path'
          expect(absolute_file_entry[:error])
            .to match(/#{template_path}.*does not exist/)

          # Does not make sense to have these keys if file does not exist.
          expect(absolute_file_entry.key?(:template_path)).to be false
          expect(absolute_file_entry.key?(:url)).to be false
        end
      end
    end

    context 'when error retrieving URL file' do
      let!(:http_error) { fake_download_error }

      it 'adds error to file entry' do
        retrieved_files = subject.retrieve(test_node)

        url_file_entry = retrieved_files[:namespace01][2]
        expect(url_file_entry[:error]).to \
          match(/#{test_url}.*#{http_error}/)

        # Does not make sense to have these keys if file not retrievable.
        expect(url_file_entry.key?(:template_path)).to be false
        expect(url_file_entry.key?(:url)).to be false
      end
    end
  end

  context 'when retrieving a plugins files' do
    let(:plugin_name) { 'some_plugin' }
    let(:plugin_path) do
      File.join(Metalware::FilePath.plugins_dir, plugin_name)
    end

    let(:plugin) do
      FileUtils.mkdir_p(plugin_path)
      Metalware::Plugins.all.find { |p| p.name == plugin_name }
    end

    before do
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
        files: { some_section: [plugin_file_path] }
      )

      plugin_namespace = Metalware::Namespaces::Plugin
                         .new(plugin, node: test_node)
      retrieved_files = subject.retrieve(plugin_namespace)

      relative_rendered_path = <<-EOF.squish
        testnode01/files/plugin/#{plugin_name}/some_section/#{plugin_file_name}
      EOF
      expect(retrieved_files).to eq(
        some_section: [{
          raw: plugin_file_path,
          name: plugin_file_name,
          template_path: absolute_plugin_file_path,
          rendered_path: data_path + "/rendered/#{relative_rendered_path}",
          url: "http://1.2.3.4/metalware/#{relative_rendered_path}",
        }]
      )
    end
  end
end
