# frozen_string_literal: true

require 'commands'
require 'fixtures/shared_context/overview'

RSpec.describe Metalware::Commands::Overview do
  include_context 'overview context'

  let(:name_hash) { { header: 'Group Name', value: '<%= group.name %>' } }

  def run_command
    AlcesUtils.redirect_std(:stdout) do
      Metalware::Utils.run_command(Metalware::Commands::Overview)
    end
  end

  before do
    allow(Metalware::Overview::Table).to \
      receive(:new).with(any_args).and_call_original
  end

  def expect_table_with(*inputs)
    expect(Metalware::Overview::Table).to \
      receive(:new).once.with(*inputs).and_call_original
  end

  context 'without overview.yaml' do
    it 'includes the name in the group table' do
      expect_table_with alces.groups, [name_hash]
      run_command
    end

    it 'makes an empty domain table' do
      expect_table_with [alces.domain], []
      run_command
    end
  end

  context 'with a overview.yaml' do
    let(:overview_hash) do
      {
        domain: [{ header: 'h1', value: 'v1' }, { header: 'h2', value: 'v2' }],
        group: fields,
      }
    end

    before do
      Metalware::Data.dump Metalware::FilePath.overview, overview_hash
    end

    it 'includes the group name and additional fields' do
      combined_fields = [name_hash].concat fields
      expect_table_with alces.groups, combined_fields
      run_command
    end

    it 'includes the additional domain table fields' do
      expect_table_with [alces.domain], overview_hash[:domain]
      run_command
    end
  end
end
