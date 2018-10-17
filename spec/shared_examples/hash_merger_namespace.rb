
# frozen_string_literal: true

require 'underware/namespaces/alces'
require 'alces_utils'

RSpec.shared_examples \
  Underware::Namespaces::HashMergerNamespace do

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
      config(subject, test_config)
      answer(subject, test_answer)
    end

    it 'converts the config into a hash' do
      expect(subject.to_h[:config]).to eq(test_config)
    end

    it 'converts the answer into a hash' do
      expect(subject.to_h[:answer]).to eq(test_answer)
    end
  end
end
