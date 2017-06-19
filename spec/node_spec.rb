
require 'node'
require 'spec_utils'


RSpec.describe Metalware::Node do
  before do
    SpecUtils.use_mock_genders(self)
    SpecUtils.use_unit_test_config(self)
  end

  def node(name)
    Metalware::Node.new(Metalware::Config.new, name)
  end

  describe '#configs' do
    it 'returns possible configs for node in precedence order' do
      testnode01 = node('testnode01')
      expect(testnode01.configs).to eq(['testnode01', 'testnodes', 'nodes', 'cluster', 'all'])
    end

    it "just returns 'node' and 'all' configs for node not in genders" do
      name = 'not_in_genders_node01'
      node = node(name)
      expect(node.configs).to eq([name, 'all'])
    end

    it "just returns 'all' when passed nil node name" do
      name = nil
      node = node(name)
      expect(node.configs).to eq(['all'])
    end
  end

  describe '#build_files' do
    it 'returns merged hash of files' do
      testnode01 = node('testnode01')
      expect(testnode01.build_files).to eq({
        namespace01: [
          'testnodes/some_file_in_repo',
          '/some/other/path',
          'http://example.com/some/url',
        ].sort,
        namespace02: [
          'another_file_in_repo',
        ].sort
      })

      testnode02 = node('testnode02')
      expect(testnode02.build_files).to eq({
        namespace01: [
          'testnode02/some_file_in_repo',
          '/some/other/path',
          'http://example.com/testnode02/some/url',
        ].sort,
        namespace02: [
          'testnode02/another_file_in_repo',
        ].sort
      })
    end
  end
end
