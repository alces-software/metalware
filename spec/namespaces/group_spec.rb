
# frozen_string_literal: true

require 'shared_examples/hash_merger_namespace'
require 'namespaces/alces'
require 'spec_utils'

RSpec.describe Metalware::Namespaces::Group do
  include AlcesUtils

  context 'with mocked group' do
    subject { alces.groups.first }

    let(:test_group) { 'some_test_group' }

    AlcesUtils.mock self, :each do
      mock_group(test_group)
      mock_node('random_node', test_group)
    end

    include_examples Metalware::Namespaces::HashMergerNamespace
  end

  context 'with a mocked genders file' do
    before do
      AlcesUtils.mock self do
        mock_group('group1')
        mock_group('group2')
      end

      genders = <<~EOF.strip_heredoc
        node[01-10]    group1,group2
        nodeA    group2
      EOF
      File.write Metalware::FilePath.genders, genders
    end

    describe '#short_nodes_string' do
      it 'can find the hosts list' do
        group = alces.groups.find_by_name('group2')
        expect(group.hostlist_nodes).to eq('node[01-10],nodeA')
      end
    end
  end
end
