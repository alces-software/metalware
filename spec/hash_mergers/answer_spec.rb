
# frozen_string_literal: true

require 'hash_mergers'
require 'alces_utils'
require 'data'
require 'file_path'

RSpec.describe Metalware::HashMergers::Answer do
  include AlcesUtils

  let(:group) { AlcesUtils.mock(self) { mock_group('new_group') } }
  let(:node) do
    AlcesUtils.mock(self) { mock_node('new_node', group.name) }
  end

  let(:identifier) { :question_identifier }
  let(:questions) do
    {
      domain: [{
        identifier: identifier.to_s,
        question: 'Ask domain question?',
        default: 'domain-default',
      }],
      group: [{
        identifier: identifier.to_s,
        question: 'Ask group question?',
        default: 'group-default', # Should be ignored
      }],
      node: [{
        identifier: identifier.to_s,
        question: 'Ask node question?',
        default: 'node-default', # Should be ignored
      }],
      local: [],
    }
  end

  def answers(namespace)
    case namespace
    when Metalware::Namespaces::Domain
      'domain_answer'
    when Metalware::Namespaces::Group
      'group_answer'
    when Metalware::Namespaces::Node
      'node_answer'
    else
      raise 'unexpected error'
    end
  end

  before do
    Metalware::Data.dump Metalware::FilePath.configure_file, questions
  end

  shared_examples 'run contexts with shared' do |spec_group|
    context 'when loading domain answers' do
      subject { alces.domain }

      include_examples spec_group
    end

    context 'when loading group answers' do
      subject { group }

      include_examples spec_group
    end

    context 'when loading node answers' do
      subject { node }

      include_examples spec_group
    end
  end

  context 'without answer files' do
    shared_examples 'uses the domain default' do
      it 'uses the domain default' do
        expect(subject.answer.send(identifier)).to eq('domain-default')
      end
    end
    include_examples 'run contexts with shared', 'uses the domain default'
  end

  context 'with answer files' do
    before do
      Metalware::Data.dump(
        Metalware::FilePath.domain_answers,
        identifier => answers(alces.domain)
      )
      Metalware::Data.dump(
        Metalware::FilePath.group_answers(group.name),
        identifier => answers(group)
      )
      Metalware::Data.dump(
        Metalware::FilePath.node_answers(node.name),
        identifier => answers(node)
      )
    end

    shared_examples 'uses the saved answer' do
      it 'uses the saved answer' do
        expect(subject.answer.send(identifier)).to eq(answers(subject))
      end
    end
    include_examples 'run contexts with shared', 'uses the saved answer'
  end
end
