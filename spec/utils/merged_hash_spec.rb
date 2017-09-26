
# frozen_string_literal: true

require 'utils/merged_hash'
require 'config'
require 'filesystem'
require 'data'

RSpec.describe Metalware::Utils::MergedHash do
  let :config { Metalware::Config.new }
  let :filesystem do
    FileSystem.setup { |fs| fs.with_repo_fixtures('repo2') }
  end

  def load_next_hash
    @hash_count ||= -1
    @hash_count += 1
    (@hash_count..10).each_with_object({}) do |idx, my_hash|
      my_hash["index_#{idx}": @hash_count]
    end
  end

  context 'with domain scope' do
    let :merged_hash { Metalware::Utils::MergedHash.new(metalware_config: config) }

    it 'returns the domain config' do
      filesystem.test do
        expect(merged_hash.config.to_h).not_to be_empty
        merged_hash.config.to_h.each do |_key, value|
          expect(value).to eq('domain')
        end
      end
    end
  end

  context 'with single group' do
    let :merged_hash do
      Metalware::Utils::MergedHash.new(
        metalware_config: config,
        groups:['group1']
      )
    end

    it 'returns the merged configs' do
      filesystem.test do
        expect(merged_hash.config.to_h).not_to be_empty
        merged_hash.config.each do |key, value|
          expected_value = case key
                           when 'value0'
                             'domain'
                           else
                             'group1'
                           end
          expect(value).to eq(expected_value)
        end
      end
    end
  end

  context 'with multiple groups' do
    let :merged_hash do
      Metalware::Utils::MergedHash.new(
        metalware_config: config,
        groups:['group1', 'group2']
      )
    end

    it 'returns the merged configs' do
      filesystem.test do
        expect(merged_hash.config.to_h).not_to be_empty
        merged_hash.config.to_h.each do |key, value|
          expected_value = case key
                           when 'value0'
                             'domain'
                           when 'value1'
                             'group1'
                           else
                             'group2'
                           end
          expect(value).to eq(expected_value)
        end
      end
    end
  end
end
