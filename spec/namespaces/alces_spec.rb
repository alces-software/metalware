
# frozen_string_literal: true

require 'namespaces/alces'
require 'hash_mergers'
require 'config'

RSpec.describe Metalware::Namespaces::Alces do
  let :config { Metalware::Config.new }
  let :unstubed_alces {}
  let :alces do
    namespace = Metalware::Namespaces::Alces.new(config)
    allow(namespace).to receive(:answer).and_return(answer(namespace))
    namespace
  end

  def answer(alces)
    Metalware::HashMergers::MetalRecursiveOpenStruct.new(alces: alces,
                                                         key: 'value',
                                                         infinite_value1: '<%= alces.answer.infinite_value2 %>',
                                                         infinite_value2: '<%= alces.answer.infinite_value1 %>')
  end

  def render_template(template)
    alces.render_erb_template(template)
  end

  describe '#template' do
    it 'it can template a simple value' do
      expect(render_template('<%= alces.answer.key %>')).to eq('value')
    end

    it 'errors if recursion depth is exceeded' do
      expect do
        output = render_template('<%= alces.answer.infinite_value1 %>')
        STDERR.puts "Template output: #{output}"
      end.to raise_error(Metalware::RecursiveConfigDepthExceededError)
    end
  end
end
