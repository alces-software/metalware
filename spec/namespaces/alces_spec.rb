
# frozen_string_literal: true

require 'namespaces/alces'
require 'hash_mergers'
require 'config'

module Metalware
  module Namespaces
    class Alces
      def testing; end
    end
  end
end

RSpec.describe Metalware::Namespaces::Alces do
  let :config { Metalware::Config.new }
  let :unstubed_alces {}
  let :alces do
    namespace = Metalware::Namespaces::Alces.new(config)
    allow(namespace).to receive(:testing).and_return(testing(namespace))
    namespace
  end

  def testing(alces)
    Metalware::HashMergers::MetalRecursiveOpenStruct
      .new(
        key: 'value',
        infinite_value1: '<%= alces.testing.infinite_value2 %>',
        infinite_value2: '<%= alces.testing.infinite_value1 %>'
      ) do |template_string|
        alces.render_erb_template(template_string)
      end
  end

  def render_template(template)
    alces.render_erb_template(template)
  end

  describe '#template' do
    it 'it can template a simple value' do
      expect(render_template('<%= alces.testing.key %>')).to eq('value')
    end

    it 'errors if recursion depth is exceeded' do
      expect do
        output = render_template('<%= alces.testing.infinite_value1 %>')
        STDERR.puts "Template output: #{output}"
      end.to raise_error(Metalware::RecursiveConfigDepthExceededError)
    end
  end
end
