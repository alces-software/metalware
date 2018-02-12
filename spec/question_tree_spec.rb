
require 'validation/configure'

RSpec.describe Metalware::QuestionTree do
  let :identifier_hash do
    {
      domain: 'domain_identifier',
      domain2: 'second_domain_identifier',
      group: 'group_identifier',
      node: 'node_identifier',
      local: 'local_identifier',
      dependent: 'dependent_identifier',
      dependent2: 'second_dependent_identifier'
    }
  end

  let :identifiers { identifier_hash.values }

  let :question_hash do
    {
      domain: [
        {
          identifier: identifier_hash[:domain],
          question: 'Am I a question for the domain?'
        },
        {
          identifier: identifier_hash[:domain2],
          question: 'Can I have two questions in a section?'
        }
      ],
      group: [
        identifier: identifier_hash[:group],
        question: 'Am I a question for the group?',
        dependent: [
          {
            identifier: identifier_hash[:dependent],
            question: 'Can I have a dependent question?'
          },
          {
            identifier: identifier_hash[:dependent2],
            question: 'Can I have a second dependent question?'
          }
        ]
      ],
      node: [
        identifier: identifier_hash[:node],
        question: 'Am I a question for the node?'
      ],
      local: [
        identifier: identifier_hash[:local],
        question: 'Am I a question for the local node?'
      ]
    }
  end

  subject { Metalware::Validation::Configure.new(question_hash).tree }

  describe '#identifiers' do
    it 'returns all the identifiers' do
      expect(subject.identifiers).to contain_exactly(*identifiers)
    end
  end
end

