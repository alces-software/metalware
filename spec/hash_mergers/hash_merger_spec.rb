
# frozen_string_literal: true

require 'hash_mergers'
require 'filesystem'
require 'data'
require 'constants'
require 'spec_utils'
require 'alces_utils'

RSpec.describe Metalware::HashMergers::HashMerger do
  include AlcesUtils

  AlcesUtils.mock self, :each do
    validation_off
  end

  let(:filesystem) do
    FileSystem.setup do |fs|
      default_config_path = Metalware::FilePath.default_config
      fs.with_repo_fixtures('merged_hash')
      fs.with_answer_fixtures('merged_hash/answers')
      fs.with_fixtures('configs/validation-off.yaml', at: default_config_path)
    end
  end

  def build_merged_hash(**hash_input)
    hm = Metalware::HashMergers
    OpenStruct.new(
      config: hm::Config.new.merge(**hash_input, &:itself),
      answer: hm::Answer.new(alces).merge(**hash_input, &:itself)
    )
  end

  def expect_config_value(my_hash)
    expect(my_hash.config.to_h).not_to be_empty
    my_hash.config.to_h.each do |key, value|
      next if key == :files
      expect(value).to eq(yield key)
    end
  end

  context 'with domain scope' do
    let(:merged_hash) { build_merged_hash }

    it 'returns the domain config' do
      filesystem.test do
        expect_config_value(merged_hash) { 'domain' }
      end
    end
  end

  context 'with single group' do
    let(:merged_hash) do
      build_merged_hash(groups: ['group2'])
    end

    it 'returns the merged configs' do
      filesystem.test do
        expect_config_value(merged_hash) do |key|
          case key
          when :value0
            'domain'
          else
            'group2'
          end
        end
      end
    end
  end

  context 'with multiple groups' do
    let(:merged_hash) do
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
    let(:merged_hash) do
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

  describe '#build_files' do
    it 'replaces the files lists (within the namespace)' do
      filesystem.test do
        merged_hash = build_merged_hash(node: 'node3')
        files = merged_hash.config.files.namespace
        expect(files.length).to eq(2)
        expect(files).to include('node3', 'duplicate')
      end
    end
  end
end
