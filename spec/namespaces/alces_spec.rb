
# frozen_string_literal: true

require 'namespaces/alces'
require 'config'

RSpec.describe Metalware::Namespaces::Alces do
  let :config { Metalware::Config.new }
  let :alces do
    namespace = Metalware::Namespaces::Alces.new(config)    
    allow(namespace).to receive(:answer).and_return(answer)
    namespace
  end

  let :answer do
    OpenStruct.new({
      key: 'value',
      infinite_value1: '<%= alces.answer.infinite_value2 %>',
      infinite_value2: '<%= alces.answer.infinite_value1 %>'
    })
  end

  describe '#template' do
    it 'it can template a simple value' do
      expect(alces.template('<%= alces.answer.key %>')).to eq('value')
    end
  end
end
