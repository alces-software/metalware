#frozen_string_literal: true

require 'commands'
require 'alces_utils'

RSpec.describe Metalware::Commands::Overview do
  include AlcesUtils

  let :config_value { 'config_value' }

  AlcesUtils.mock self, :each do
    ['group1', 'group2', 'group3'].map do |group|
      mock_group(group)
      config(alces.group, { key: config_value })
    end
  end

  def overview
    std = AlcesUtils.redirect_std(:stdout) do
      Metalware::Utils.run_command(Metalware::Commands::Overview)
    end
    std[:stdout].read
  end

  def header
    overview.lines[1]
  end

  def body
    overview.lines[3..-2].join("\n")
  end

  it 'includes the group names' do
    expect(header).to include("Group")
    alces.groups.each do |group|
      expect(body).to include(group.name)
    end
  end

  context 'with a mismatch between no. headers/bodies in overview.yaml' do
    before :each do
      Metalware::Data.dump(Metalware::FilePath.overview, {
        headers: ['I', 'have', '4', 'headers'],
        fields: ['I', 'have', '5', 'body', 'parts'],
      })
    end

    it 'errors' do
      AlcesUtils.redirect_std(:stderr) do
        expect { overview }.to raise_error(Metalware::DataError)
      end
    end
  end

  context 'with a valid overview.yaml' do
    let :static { 'static' }
    let :headers { ['heading1', 'heading2', 'heading3'] }
    let :fields { [static, '<% group.config.value %>', ''] }

    before :each do
      Metalware::Data.dump Metalware::FilePath.overview,
                           { headers: headers, fields: fields }
    end

    it 'includes the headers in the table' do
      headers.each { |h| expect(header).to include(h) }
    end

    it 'includes the static field in the table' do
      expect(body).to include(static)
    end

    it 'renders the fields' do
      expect(body).to include(config_value)
    end
  end
end

