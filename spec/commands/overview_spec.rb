# frozen_string_literal: true

require 'commands'
require 'alces_utils'

RSpec.describe Metalware::Commands::Overview::Table do
  include AlcesUtils

  let :config_value { 'config_value' }
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

  AlcesUtils.mock self, :each do
    ['group1', 'group2', 'group3'].map do |group|
      config(mock_group(group), key: config_value)
    end
  end

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

  # TODO: Make a Commands::Overview spec and move this into it
  # This no longer is applicable here
  xit 'includes the group names' do
    expect(header).to include('Group')
    alces.groups.each do |group|
      expect(body).to include(group.name)
    end
  end

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

