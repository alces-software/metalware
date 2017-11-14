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

require 'spec_helper'

require 'node'
require 'spec_utils'
require 'fileutils'
require 'config'
require 'constants'
require 'filesystem'
require 'validation/loader'
require 'validation/answer'

RSpec.describe Metalware::Node do
  def node(name)
    Metalware::Node.new(config, name, **node_args)
  end

  let :node_args { {} }

  let :testnode01 { node('testnode01') }
  let :testnode02 { node('testnode02') }
  let :testnode03 { node('testnode03') }
  let :config { Metalware::Config.new }

  before do
    SpecUtils.use_mock_genders(self)
  end

  # XXX adapt these to use FakeFS and make dependencies explicit?
  context 'without using FakeFS', real_fs: true do
    before do
      SpecUtils.use_unit_test_config(self)
    end

    describe '#configs' do
      it 'returns ordered configs for node, lowest precedence first' do
        expect(testnode01.configs).to eq(['domain', 'cluster', 'nodes', 'testnodes', 'testnode01'])
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

    describe '#groups' do
      it 'returns ordered groups for node, highest precedence first' do
        expect(testnode01.groups).to eq(['testnodes', 'nodes', 'cluster'])
      end

      it 'returns [] for node not in genders' do
        name = 'not_in_genders_node01'
        node = node(name)
        expect(node.groups).to eq([])
      end

      context 'when node created with `should_be_configured` option' do
        let :node_args { { should_be_configured: true } }

        # TODO: same as test outside this context.
        it 'returns ordered groups for node, highest precedence first' do
          expect(testnode01.groups).to eq(['testnodes', 'nodes', 'cluster'])
        end

        it 'raises for node not in genders' do
          name = 'not_in_genders_node01'
          node = node(name)
          expect { node.groups }.to raise_error Metalware::NodeNotInGendersError
        end
      end
    end

    describe '#index' do
      it "returns consistent index of node within its 'primary' group" do
        # We define the 'primary' group for a node as the first group it is
        # associated with in the genders file. This means for `testnode01` and
        # `testnode03` this is `testnodes`, but for `testnode02` it is
        # `pregroup`, in which it is the first node and so has index 1.
        #
        # This has the potential to cause confusion but I see no better way to
        # handle this currently, as a node can always have multiple groups and we
        # have to choose one to be the primary group. Later we may add more
        # structure and validation around handling this.
        expect(testnode01.index).to eq(1)
        expect(testnode02.index).to eq(1)
        expect(testnode03.index).to eq(3)
      end

      it 'returns 0 for node not in genders' do
        name = 'not_in_genders_node01'
        node = node(name)
        expect(node.index).to eq(0)
      end

      it 'returns 0 for nil node name' do
        node = node(nil)
        expect(node.index).to eq(0)
      end
    end
  end

  describe '#group_index' do
    let :filesystem { FileSystem.setup }

    it 'returns 0 when groups.yaml does not exist' do
      # This should never happen now as a node should always have a primary
      # group, which should be in the cache.
      expect(testnode01.group_index).to eq 0
    end

    context 'when some primary groups have been cached' do
      before :each do
        filesystem.with_group_cache_fixture('cache/groups.yaml')
      end

      it "returns the index of the node's primary group" do
        filesystem.test do
          expect(testnode01.group_index).to eq(2)
        end
      end

      it "raises when the node's primary group is not in the cache" do
        # This should never happen now as a node should always have a primary
        # group.
        expect(testnode02.group_index).to eq 0
      end

      it 'returns 0 for the null object node' do
        expect(node(nil).group_index).to eq 0
      end
    end
  end

  describe '#raw_config' do
    it 'performs a deep merge of all config files' do
      expected_answers = {
        networks: {
          foo: 'not bar',
          something: 'value',
          prv: {
            ip: '10.10.0.1',
            interface: 'eth1',
          },
        },
      }

      FileSystem.test do |fs|
        fs.with_repo_fixtures('repo_deep_merge')
        config = Metalware::Config.new
        node = Metalware::Node.new(config, 'deepmerge')
        expect(node.raw_config).to eq(expected_answers)
      end
    end
  end

  describe '#answers' do
    let :config { Metalware::Config.new }
    let :loader { Metalware::Validation::Loader.new(config) }
    let :configure_data do
      questions = {
        value_left_as_default: { default: 'default' },
        value_set_by_domain: { default: 'default' },
        value_set_by_ag1: { default: 'default' },
        value_set_by_ag2: { default: 'default' },
        value_set_by_answer1: { default: 'default' },
      }

      {
        domain: questions,
        group: questions,
        node: questions,
        self: {},
      }
    end

    let :filesystem do
      FileSystem.setup { |fs| fs.with_answer_fixtures('answers/node-test-set1') }
    end

    before :each do
      allow(loader).to receive(:configure_data).and_return(configure_data)
      allow(Metalware::Validation::Loader).to receive(:new).and_return(loader)
      # Turns off answer file validation as they do not match the configure.yaml
      allow_any_instance_of(Metalware::Validation::Answer).to \
        receive(:success?).and_return(true)
    end

    it 'performs a deep merge of defaults and answer files' do
      expected_answers = {
        value_left_as_default: 'default',
        value_set_by_domain: 'domain',
        value_set_by_ag1: 'ag1',
        value_set_by_ag2: 'ag2',
        value_set_by_answer1: 'answer1',
      }

      filesystem.test do
        answers = node('answer1').answers
        expect(answers).to eq(expected_answers)
      end
    end

    it 'just includes default or domain answers for nil node name' do
      # A nil node uses no configs but the 'domain' config, so all answers will
      # be loaded from the 'domain' answers file.
      expected_answers = {
        value_left_as_default: 'default',
        value_set_by_domain: 'domain',
        value_set_by_ag1: 'domain',
        value_set_by_ag2: 'domain',
        value_set_by_answer1: 'domain',
      }

      filesystem.test do
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

  # Not ideal testing the private method, however their is specific behaviour
  # required for the self node
  describe '#build_method_class' do
    let :build_node { Metalware::Node.new(config, 'name_to_be_mocked') }

    def build_method_class(node_name, build_method)
      allow(build_node).to receive(:name).and_return(node_name)
      repo_config = build_method.nil? ? {} : { build_method: build_method }
      allow(build_node).to receive(:repo_config).and_return(repo_config)
      build_node.send(:build_method_class)
    end

    context 'with a regular node' do
      it 'returns the default (/kickstart) build method if not specified' do
        expected = Metalware::BuildMethods::Kickstarts::Pxelinux
        expect(build_method_class('build_node', nil)).to eq(expected)
      end

      it 'returns the build method if specified' do
        expected = Metalware::BuildMethods::Basic
        expect(build_method_class('build_node', :basic)).to eq(expected)
      end

      it 'errors if the self build method is used' do
        expect do
          build_method_class('build_node', :self)
        end.to raise_error(Metalware::SelfBuildMethodError)
      end
    end

    context "with the 'self' node" do
      it 'returns the self build method if not specified' do
        expected = Metalware::BuildMethods::Self
        expect(build_method_class('self', nil)).to eq(expected)
      end

      it 'returns the self build method if specified' do
        expected = Metalware::BuildMethods::Self
        expect(build_method_class('self', :self)).to eq(expected)
      end

      it 'errors if the build method is not self' do
        expect do
          build_method_class('self', :basic)
        end.to raise_error(Metalware::SelfBuildMethodError)
      end
    end
  end
end
