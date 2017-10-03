
# frozen_string_literal: true

require 'hash_mergers'
require 'config'
require 'filesystem'
require 'namespaces/alces'

module Metalware
  module Namespaces
    class Alces
      def testing; end
    end
  end
end

RSpec.describe Metalware::HashMergers::MetalRecursiveOpenStruct do
  let :config { Metalware::Config.new }
  let :alces do
    namespace = Metalware::Namespaces::Alces.new(config)
    allow(namespace).to receive(:testing).and_return(build_hash(namespace))
    namespace
  end

  let :struct { build_hash(alces) }

  def build_hash(_alces_input)
    Metalware::HashMergers::MetalRecursiveOpenStruct
      .new(
        key: 'value',
        erb1: '<%= alces.testing.key %>',
        erb2: '<%= alces.testing.erb1 %>',
        erb3: '<%= alces.testing.erb2 %>',
        erb4: '<%= alces.testing.erb3 %>',
        recursive_hash1: {
          recursive_hash2: '<%= alces.testing.key %>'
        }
      ) do |template_string|
        alces.render_erb_template(template_string)
      end
  end

  it 'does a single ERB replacement' do
    expect(struct.erb1).to eq('value')
  end

  it 'can replace multiple embedded erb' do
    expect(struct.erb4).to eq('value')
  end

  it 'can loop through the entire structure' do
    struct.each do |key, value|
      next if value.is_a? Metalware::HashMergers::MetalRecursiveOpenStruct
      exp = struct.send(key)
      msg = "#{key} was not rendered, expected: '#{exp}', got: '#{value}'"
      expect(exp).to eq(value), msg
    end
  end

  it 'renderes parameters in a recursive hash' do
    expect(struct.recursive_hash1.recursive_hash2).to eq('value')
  end
end
