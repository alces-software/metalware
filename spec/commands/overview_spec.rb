# frozen_string_literal: true

require 'commands'
require 'alces_utils'

RSpec.shared_context 'mock overview namespaces' do
  include AlcesUtils
  let :config_value { 'config_value' }

  AlcesUtils.mock self, :each do
    ['group1', 'group2', 'group3'].map do |group|
      config(mock_group(group), key: config_value)
    end
  end
end

RSpec.describe Metalware::Commands::Overview do
  include_context 'mock overview namespaces'

  def run_command
    AlcesUtils.redirect_std(:stdout) do
      Metalware::Utils.run_command(Metalware::Commands::Overview)
    end
  end

  context 'without overview.yaml' do
    it 'includes the name in the group table' do
      name_hash = { header: 'Group Name', value: '<%= group.name %>' }
      expect(Metalware::Commands::Overview::Table).to \
        receive(:new).with(alces.groups, [name_hash]).and_call_original
      run_command
    end
  end
end

RSpec.describe Metalware::Commands::Overview::Table do
  include_context 'mock overview namespaces'

  let :fields do
    [
      { header: 'heading1', value: static },
      { header: 'heading2', value: '<%= scope.config.key %>' },
      { header: 'heading3', value: '' },
      { header: 'missing-value' },
      { value: 'missing-header' }
    ]
  end
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

  let :static { 'static' }
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

