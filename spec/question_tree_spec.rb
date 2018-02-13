
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

  shared_examples 'a filtered traversal' do |base_method|
    let :filtered_method { :"filtered_#{base_method}" }
    let :enum { subject.public_send(filtered_method) }

    it 'is defined' do
      expect(subject).to respond_to(filtered_method)
    end

    it 'only includes questions' do
      enum.each { |q| expect(q).to be_question }
    end

    it 'returns an enumerator when called without a block' do
      expect(enum).to be_a Enumerator
    end

    it 'runs the block for each valid question' do
      num = 0
      subject.send filtered_method do |_q|
        num += 1
      end
      expect(num).to eq(identifiers.length)
    end
  end

  Metalware::QuestionTree::BASE_TRAVERSALS.each do |base_method|
    describe "#filtered_#{base_method}" do
      it_behaves_like "a filtered traversal", base_method
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

