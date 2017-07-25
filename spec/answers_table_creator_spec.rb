
# frozen_string_literal: true

require 'spec_utils'

require 'filesystem'
require 'answers_table_creator'

RSpec.describe Metalware::AnswersTableCreator do
  subject do
    Metalware::AnswersTableCreator.new(Metalware::Config.new)
  end

  let :configure_data do
    {
      domain: {
        question_1: { question: 'question 1' },
      },
      group: {
        question_1: { question: 'question 1' },
        question_2: { question: 'question 2', type: 'integer' },
      },
      node: {
        question_1: { question: 'question 1' },
        question_2: { question: 'question 2', type: 'integer' },
        question_3: { question: 'question 3' },
      },
    }
  end

  let :domain_answers do
    { question_1: 'domain question 1' }
  end

  let :group_answers do
    { question_1: 'group question 1', question_2: 11 }
  end

  let :node_answers do
    {
      question_1: 'node question 1',
      question_2: 13,
      question_3: 'node question 3',
    }
  end

  let :group_name { 'testnodes' }

  let :node_name { 'testnode01' }

  let :filesystem do
    FileSystem.setup do |fs|
      fs.dump('/var/lib/metalware/repo/configure.yaml', configure_data)
      fs.dump('/var/lib/metalware/answers/domain.yaml', domain_answers)
      fs.dump("/var/lib/metalware/answers/groups/#{group_name}.yaml", group_answers)
      fs.dump("/var/lib/metalware/answers/nodes/#{node_name}.yaml", node_answers)
    end
  end

  before do
    SpecUtils.use_mock_genders(self)
  end

  describe '#domain_table' do
    it 'creates table with questions and domain answers' do
      filesystem.test do
        expected_table = Terminal::Table.new(
          headings: ['Question', 'Domain'],
          rows: [
            ['question_1', '"domain question 1"'],
            ['question_2', 'nil'],
            ['question_3', 'nil'],
          ]
        )

        # In this and following tests, convert tables to strings so can compare
        # output rather than as objects (which will never be equal as we create
        # different `Table`s).
        expect(
          subject.domain_table.to_s
        ).to eq expected_table.to_s
      end
    end
  end

  describe '#primary_group_table' do
    it 'creates table with questions, and domain and primary group answers' do
      filesystem.test do
        expected_table = Terminal::Table.new(
          headings: ['Question', 'Domain', "Group: #{group_name}"],
          rows: [
            ['question_1', '"domain question 1"', '"group question 1"'],
            ['question_2', 'nil', '11'],
            ['question_3', 'nil', 'nil'],
          ]
        )

        expect(
          subject.primary_group_table(group_name).to_s
        ).to eq expected_table.to_s
      end
    end
  end

  describe '#node_table' do
    it 'creates table with questions, and domain, primary group, and node answers' do
      filesystem.test do
        expected_table = Terminal::Table.new(
          headings: ['Question', 'Domain', "Group: #{group_name}", "Node: #{node_name}"],
          rows: [
            ['question_1', '"domain question 1"', '"group question 1"', '"node question 1"'],
            ['question_2', 'nil', '11', '13'],
            ['question_3', 'nil', 'nil', '"node question 3"'],
          ]
        )

        expect(
          subject.node_table(node_name).to_s
        ).to eq expected_table.to_s
      end
    end
  end
end
