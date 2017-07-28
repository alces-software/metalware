
# frozen_string_literal: true

require 'spec_utils'
require 'filesystem'

RSpec.describe Metalware::Commands::Configure::Node do
  def run_configure_node(node)
    SpecUtils.run_command(
      Metalware::Commands::Configure::Node, node
    )
  end

  let :config { Metalware::Config.new }

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
  end

  it 'creates correct configurator' do
    filesystem.test do
      expect(Metalware::Configurator).to receive(:new).with(
        configure_file: config.configure_file,
        questions_section: :node,
        answers_file: config.node_answers_file('testnode01'),
        higher_level_answer_files: []
      ).and_call_original

      run_configure_node 'testnode01'
    end
  end
end
