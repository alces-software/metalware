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
      expect(testnode01.configs).to eq(["all", "cluster", "nodes", "testnodes", "testnode01"])
    end

    it "just returns 'node' and 'all' configs for node not in genders" do
      name = 'not_in_genders_node01'
      node = node(name)
      expect(node.configs).to eq(['all', name])
    end

    it "just returns 'all' when passed nil node name" do
      name = nil
      node = node(name)
      expect(node.configs).to eq(['all'])
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
