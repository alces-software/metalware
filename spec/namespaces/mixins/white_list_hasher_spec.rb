
# frozen_string_literal: true

require 'namespaces/mixins/white_list_hasher'
require 'ostruct'

RSpec.describe Metalware::Namespaces::Mixins::WhiteListHasher do
  let :test_obj do
    double(
      white_method1: 1,
      white_method2: 2,
      white_method3: 3,
      recursive_hash_obj: recursive_hash_obj,
      do_not_hash_me: 'ohh snap',
      white_list_for_hasher: white_list,
      recursive_white_list_for_hasher: recursive_white_list
    ).extend Metalware::Namespaces::Mixins::WhiteListHasher
  end

  let :recursive_hash_obj do
    OpenStruct.new(am_i_a_ostuct: 'no, I should be a hash')
  end

  let :white_list { (1..3).map { |i| "white_method#{i}" } }
  let :recursive_white_list { ['recursive_hash_obj'] }

  let :test_hash { test_obj.to_h }
  let :expected_number_of_keys do
    white_list.length + recursive_white_list.length
  end

  it 'has all the white listed methods' do
    expect(test_hash.keys).to include(*white_list)
  end

  it 'has the recursive listed methods' do
    expect(test_hash.keys).to include(*recursive_white_list)
  end

  it 'has the correct number of keys' do
    expect(test_hash.keys.length).to eq(expected_number_of_keys)
  end
end
