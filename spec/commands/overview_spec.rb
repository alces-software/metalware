# frozen_string_literal: true

require 'commands'
require 'alces_utils'

RSpec.shared_context 'mock overview namespaces' do
  include AlcesUtils
  let :config_value { 'config_value' }
  let :static { 'static' }
  let :fields do
    [
      { header: 'heading1', value: static },
      { header: 'heading2', value: '<%= scope.config.key %>' },
      { header: 'heading3', value: '' },
      { header: 'missing-value' },
      { value: 'missing-header' }
    ]
  end

  AlcesUtils.mock self, :each do
    ['group1', 'group2', 'group3'].map do |group|
      config(mock_group(group), key: config_value)
    end
  end
end

RSpec.describe Metalware::Commands::Overview do
  include_context 'mock overview namespaces'

  let :name_hash { { header: 'Group Name', value: '<%= group.name %>' } }

  def run_command
    AlcesUtils.redirect_std(:stdout) do
      Metalware::Utils.run_command(Metalware::Commands::Overview)
    end
  end

  before :each do
    allow(Metalware::Commands::Overview::Table).to \
      receive(:new).with(any_args).and_call_original
  end

  def expect_table_with(*inputs)
    expect(Metalware::Commands::Overview::Table).to \
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
    let :overview_hash { { group: fields } }

    before :each do
      Metalware::Data.dump Metalware::FilePath.overview, overview_hash
    end

    it 'includes the group name and additional fields' do
      combined_fields = [name_hash].concat fields
      expect_table_with alces.groups, combined_fields
      run_command
    end
  end
end

RSpec.describe Metalware::Commands::Overview::Table do
  include_context 'mock overview namespaces'

  let :namespaces { alces.groups }

  let :table do
    Metalware::Commands::Overview::Table.new(namespaces, fields).render
  end

  def header
    table.lines[1]
  end

  def body
    table.lines[3..-2].join("\n")
  end

  let :headers { fields.map { |h| h[:header] } }

  it 'includes the headers in the table' do
    headers.each do |h|
      expect(header).to include(h) unless h.nil?
    end
  end

  it 'includes the static value in the table' do
    expect(body).to include(static)
  end

  it 'renders the values' do
    expect(body).to include(config_value)
  end
end

