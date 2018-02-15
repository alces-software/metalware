#frozen_string_literal: true

require 'commands'
require 'alces_utils'

RSpec.describe Metalware::Commands::Overview do
  include AlcesUtils

  AlcesUtils.mock self, :each do
    ['group1', 'group2', 'group3'].map { |group| mock_group(group) }
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
end

