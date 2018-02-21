# frozen_string_literal: true

require 'commands'
require 'alces_utils'

RSpec.describe Metalware::Commands::Overview::Group do
  include AlcesUtils

  let :config_value { 'config_value' }

  AlcesUtils.mock self, :each do
    ['group1', 'group2', 'group3'].map do |group|
      config(mock_group(group), key: config_value)
    end
  end

  def table
    Metalware::Commands::Overview::Group.new(alces).table.render
  end

  def header
    table.lines[1]
  end

  def body
    table.lines[3..-2].join("\n")
  end

  context 'without a configure.yaml' do
    it 'does not error' do
      expect { table }.not_to raise_error
    end
  end

  context 'with a configure.yaml' do
    let :overview_yaml do
      {
        group: [
          { header: 'heading1', value: static },
          { header: 'heading2', value: '<%= group.config.key %>' },
          { header: 'heading3', value: '' },
          { header: 'missing-value' },
          { value: 'missing-header' }
        ]
      }
    end
    let :static { 'static' }
    let :headers { overview_yaml[:group].map { |h| h[:header] } }

    before :each do
      Metalware::Data.dump Metalware::FilePath.overview, overview_yaml
    end

    it 'includes the group names' do
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
end

