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

require 'spec_helper'

require 'node'
require 'spec_utils'
require 'fileutils'
require 'config'
require 'constants'
require 'filesystem'

RSpec.describe Metalware::Node do
  def node(name)
    Metalware::Node.new(Metalware::Config.new, name)
  end

  let :testnode01 { node('testnode01') }
  let :testnode02 { node('testnode02') }
  let :testnode03 { node('testnode03') }

  before do
    SpecUtils.use_mock_genders(self)
  end

  # XXX adapt these to use FakeFS and make dependencies explicit?
  context 'without using FakeFS' do
    before do
      SpecUtils.use_unit_test_config(self)
    end

    describe '#configs' do
      it 'returns possible configs for node in precedence order' do
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

    describe '#build_files' do
      it 'returns merged hash of files' do
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

    describe '#index' do
      it "returns consistent index of node within its 'primary' group" do
        # We define the 'primary' group for a node as the first group it is
        # associated with in the genders file. This means for `testnode01` and
        # `testnode03` this is `testnodes`, but for `testnode02` it is
        # `pregroup`, in which it is the first node and so has index 0.
        #
        # This has the potential to cause confusion but I see no better way to
        # handle this currently, as a node can always have multiple groups and we
        # have to choose one to be the primary group. Later we may add more
        # structure and validation around handling this.
        expect(testnode01.index).to eq(0)
        expect(testnode02.index).to eq(0)
        expect(testnode03.index).to eq(2)
      end

      it "returns 0 for node not in genders" do
        name = 'not_in_genders_node01'
        node = node(name)
        expect(node.index).to eq(0)
      end

      it "returns 0 for nil node name" do
        node = node(nil)
        expect(node.index).to eq(0)
      end
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

  describe "#answers" do
    let :config { Metalware::Config.new }

    it 'performs a deep merge of answer files' do
      expected_answers = {
        value_set_by_domain: "domain",
        value_set_by_ag1: "ag1",
        value_set_by_ag2: "ag2",
        value_set_by_answer1: "answer1"
      }

      FileSystem.test do |fs|
        fs.with_answer_fixtures('answers/node-test-set1')
        answers = node('answer1').answers
        expect(answers).to eq(expected_answers)
      end
    end

    it 'just includes domain answers for nil node name' do
      # A nil node uses no configs but the 'domain' config, so all answers will
      # be loaded from the 'domain' answers file.
      expected_answers = {
        value_set_by_domain: "domain",
        value_set_by_ag1: "domain",
        value_set_by_ag2: "domain",
        value_set_by_answer1: "domain"
      }

      FileSystem.test do |fs|
        fs.with_fixtures('answers/node-test-set1', at: config.answer_files_path)
        answers = node(nil).answers
        expect(answers).to eq(expected_answers)
      end
    end
  end


  describe '#==' do
    it 'returns false if other object is not a Node' do
      other_object = Struct.new(:name).new('foonode')
      expect(node('foonode')).not_to eq(other_object)
    end

    it 'defines nodes with the same name as equal' do
      expect(node('foonode')).to eq(node('foonode'))
    end

    it 'defines nodes with different names as not equal' do
      expect(node('foonode')).not_to eq(node('barnode'))
    end
  end
end
