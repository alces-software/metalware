
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

  describe '#each' do
    let :skipped_nodes do
      subject.children << subject
    end

    it 'does not include the skipped node' do
      subject.each do |question|
        expect(skipped_nodes).not_to include(question)
      end
    end
  end

  describe '#identifiers' do
    it 'returns all the identifiers' do
      expect(subject.identifiers).to contain_exactly(*identifiers)
    end
  end

  describe '#question?' do
    # The root is not a question, it stores references to the sections
    it "is false for the Tree's root" do
      expect(subject).not_to be_question
    end

    it 'is false for all section nodes' do
      subject.children.each do |section_node|
        expect(section_node).not_to be_question
      end
    end

    it 'is true for all other questions' do
      subject.each do |question|
        expect(question).to be_question
      end
    end
  end

  describe '#questions_length' do
    it 'does not include the non questions in the length' do
      expect(subject.questions_length).to eq(identifiers.length)
    end
  end
end

