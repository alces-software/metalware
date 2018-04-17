
# frozen_string_literal: true

require 'namespaces/alces'
require 'alces_utils'

RSpec.shared_examples \
  Metalware::Namespaces::HashMergerNamespace do |test_obj_str|

  let(:test_obj) { eval(test_obj_str) }

  let(:test_config) do
    {
      test_config: 'I am the config',
      files: [],
    }
  end

  let(:test_answer) do
    { test_answer: 'I am the answer' }
  end

  describe '#to_h' do
    AlcesUtils.mock self, :each do
      config(test_obj, test_config)
      answer(test_obj, test_answer)
    end

    it 'converts the config into a hash' do
      expect(test_obj.to_h[:config]).to eq(test_config)
    end

    it 'converts the answer into a hash' do
      expect(test_obj.to_h[:answer]).to eq(test_answer)
    end
  end
end
