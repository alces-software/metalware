
require 'templating/group_namespace'
require 'filesystem'


RSpec.describe Metalware::Templating::GroupNamespace do
  subject do
    Metalware::Templating::GroupNamespace.new(
      Metalware::Config.new,
      group_name
    )
  end

  let :group_name { 'testgroup' }

  let :filesystem {
    FileSystem.setup do |fs|
      fs.with_minimal_repo
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
        expect(subject.answers).to eq({
          domain_value: 'domain_value',
          overriding_domain_value: 'testgroup_value',
          genders_host_range: 'node0[10-20]',
        })
      end
    end
  end
end
