
# frozen_string_literal: true

require 'spec_utils'
require 'filesystem'
require 'group_cache'

RSpec.describe Metalware::Commands::Configure::Node do
  def run_configure_node(node)
    Metalware::Utils.run_command(
      Metalware::Commands::Configure::Node, node
    )
  end

  let :config { Metalware::Config.new }
  let :initial_alces { Metalware::Namespaces::Alces.new(config) }
  let :alces do
    allow(initial_alces).to receive(:groups).and_return(
      double('groups', testnodes: test_group)
    )
    initial_alces
  end

  let :test_group do
    Metalware::Namespaces::Group.new(initial_alces, 'testnodes', index: 1)
  end

  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_minimal_repo
      fs.dump(config.domain_answers_file, {})
      fs.dump(config.group_answers_file('testnodes'), {})
    end
  end

  before :each do
    SpecUtils.use_mock_genders(self)
    SpecUtils.mock_validate_genders_success(self)
    allow(Metalware::Namespaces::Alces).to receive(:new).and_return(alces)
  end

  it 'creates correct configurator' do
    filesystem.test do
      expect(Metalware::Configurator).to receive(:new).with(
        config: instance_of(Metalware::Config),
        questions_section: :node,
        name: 'testnode01'
      ).and_call_original

      run_configure_node 'testnode01'
    end
  end
end
