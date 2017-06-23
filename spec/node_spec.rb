
require 'spec_helper'

require 'node'
require 'spec_utils'
require 'fileutils'
require 'config'
require 'constants'
require 'fakefs_helper'

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
      expect(testnode01.configs).to eq(["domain", "cluster", "nodes", "testnodes", "testnode01"])
    end

    it "just returns 'node' and 'domain' configs for node not in genders" do
      name = 'not_in_genders_node01'
      node = node(name)
      expect(node.configs).to eq(['domain', name])
    end

    it "just returns 'domain' when passed nil node name" do
      name = nil
      node = node(name)
      expect(node.configs).to eq(['domain'])
    end
  end

  describe '#raw_config' do
    it 'performs a deep merge of all config files' do
      config = Metalware::Config.new(File.join(FIXTURES_PATH, "configs/deep-merge.yaml"))
      node = Metalware::Node.new(config, 'deepmerge')
      expect(node.raw_config).to eq({
        networks: {
          foo: 'not bar',
          something: 'value',
          prv: {
            ip: "10.10.0.1",
            interface: "eth1"
          }
        }
      })
    end
  end

  describe "#answer_hash" do
    it 'performs a deep merge of answer files' do
      config = Metalware::Config.new
      @fshelper = FakeFSHelper.new(config)
      answers = Dir[File.join(FIXTURES_PATH, "answers/node-test-set1/*")]
      @fshelper.load_config_files
      @fshelper.add_answer_files(answers)
      expected_hash = {
        value_set_by_domain: "domain",
        value_set_by_ag1: "ag1",
        value_set_by_ag2: "ag2",
        value_set_by_answer1: "answer1"
      }

      result_hash = @fshelper.run do
        Metalware::Node.new(config, 'answer1').answers
      end
      expect(result_hash).to eq(expected_hash)
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
