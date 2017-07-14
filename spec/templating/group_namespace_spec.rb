
require 'templating/group_namespace'
require 'filesystem'


RSpec.describe Metalware::Templating::GroupNamespace do
  subject do
    Metalware::Templating::GroupNamespace.new(
      Metalware::Config.new,
      group_name
    )
  end

  let :group_name { 'testnodes' }

  let :filesystem {
    FileSystem.setup do |fs|
      fs.with_repo_fixtures('repo')
      fs.with_answer_fixtures('answers/group_namespace_tests')
    end
  }

  describe '#name' do
    it 'returns the name of the group' do
      filesystem.test do
        expect(subject.name).to eq(group_name)
      end
    end
  end

  describe '#answers' do
    it 'returns the group answers merged into the domain answers' do
      filesystem.test do
        expect(subject.answers.to_h).to eq({
          domain_value: 'domain_value',
          overriding_domain_value: 'testnodes_value',
          genders_host_range: 'node0[10-20]',
        })
      end
    end
  end

  describe '#nodes' do
    it 'calls the block with templater config for each node in the group' do
      SpecUtils.use_mock_genders(self, genders_file: 'genders/group_namespace')

      filesystem.test do
        node_names = []
        some_repo_values = []

        subject.nodes do |node|
          node_names << node.alces.nodename
          some_repo_values << node.some_repo_value
        end

        expect(node_names).to eq([
          'node01','node05','node10', 'node11', 'node12'
        ])

        expected_repo_values = (['repo_value'] * 5).tap do |expected|
          expected[1] = 'value_just_for_node05'
        end
        expect(some_repo_values).to eq(expected_repo_values)
      end
    end
  end
end
