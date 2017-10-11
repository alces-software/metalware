
# frozen_string_literal: true

require 'hash_mergers'
require 'config'
require 'filesystem'
require 'data'
require 'constants'
require 'spec_utils'

RSpec.describe Metalware::HashMergers::HashMerger do
  let :config { Metalware::Config.new }
  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_repo_fixtures('merged_hash')
      fs.with_answer_fixtures('merged_hash/answers')
      fs.with_fixtures('configs/validation-off.yaml', at: Metalware::Constants::DEFAULT_CONFIG_PATH)
    end
  end

  def build_merged_hash(**hash_input)
    Metalware::HashMergers.merge(config, **hash_input)
  end

  def expect_config_value(my_hash)
    expect(my_hash.config.to_h).not_to be_empty
    my_hash.config.to_h.each do |key, value|
      next if key == :files
      expect(value).to eq(yield key)
    end
  end

  context 'with domain scope' do
    let :merged_hash { build_merged_hash }

    it 'returns the domain config' do
      filesystem.test do
        expect_config_value(merged_hash) { 'domain' }
      end
    end
  end

  context 'with single group' do
    let :merged_hash do
      build_merged_hash(groups: ['group1'])
    end

    it 'returns the merged configs' do
      filesystem.test do
        expect_config_value(merged_hash) do |key|
          case key
          when :value0
            'domain'
          else
            'group1'
          end
        end
      end
    end
  end

  context 'with multiple groups' do
    let :merged_hash do
      build_merged_hash(groups: ['group1', 'group2'])
    end

    it 'returns the merged configs' do
      filesystem.test do
        expect_config_value(merged_hash) do |key|
          case key
          when :value0
            'domain'
          when :value1
            'group2'
          else
            'group1'
          end
        end
      end
    end
  end

  context 'with multiple groups and a node' do
    let :merged_hash do
      build_merged_hash(
        groups: ['group1', 'group2'],
        node: 'node3'
      )
    end

    def check_node_hash(my_hash = {})
      expect(my_hash).not_to be_empty
      my_hash.each do |key, value|
        next if key == :files
        expected_value = case key
                         when :value0
                           'domain'
                         when :value1
                           'group2'
                         when :value2
                           'group1'
                         else
                           'node3'
                         end
        expect(value).to eq(expected_value)
      end
    end

    it 'returns the merged configs' do
      filesystem.test do
        check_node_hash(merged_hash.config.to_h)
      end
    end

    it 'returns the correct answers' do
      filesystem.test do
        check_node_hash(merged_hash.answer.to_h)
      end
    end
  end
end
