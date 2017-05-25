
require 'build_files_retriever'
require 'input'


describe Metalware::BuildFilesRetriever do
  TEST_FILES_HASH = {
    namespace01: [
      'some_file_in_repo',
      '/some/other/path',
      'http://example.com/url',
    ],
    namespace02: [
      'another_file'
    ]
  }

  before do
    SpecUtils.use_mock_determine_hostip_script(self)
    SpecUtils.use_unit_test_config(self)
  end

  describe '#retrieve' do
    context 'when everything works' do
      it 'returns the correct files object' do
        allow(Metalware::Input).to receive(:download)

        retriever = Metalware::BuildFilesRetriever.new('testnode01', Metalware::Config.new)
        retrieved_files = retriever.retrieve(TEST_FILES_HASH)

        expect(retrieved_files[:namespace01][0]).to eq({
          raw: 'some_file_in_repo',
          name: 'some_file_in_repo',
          template_path: '/var/lib/metalware/repo/files/some_file_in_repo',
          url: 'http://1.2.3.4/testnode01/namespace01/some_file_in_repo',
        })

        expect(retrieved_files[:namespace01][1]).to eq({
          raw: '/some/other/path',
          name: 'path',
          template_path: '/some/other/path',
          url: 'http://1.2.3.4/testnode01/namespace01/path',
        })

        expect(retrieved_files[:namespace01][2]).to eq({
          raw: 'http://example.com/url',
          name: 'url',
          template_path: '/var/lib/metalware/cache/templates/url',
          url: 'http://1.2.3.4/testnode01/namespace01/url',
        })
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
  end

end
