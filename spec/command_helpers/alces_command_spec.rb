
# frozen_string_literal: true

require 'command_helpers/alces_command'
require 'alces_utils'

RSpec.describe Metalware::CommandHelpers::AlcesCommand do
  include AlcesUtils

  let :domain_config { Hash.new(key: 'I am the domain config') }

  let :node { 'node01' }
  let :group { 'group1' }

  AlcesUtils.mock self, :each do
    config(alces.domain, domain_config)
    mock_group(group)
    mock_node(node)
  end

  #
  # The purpose of the mixin is to provide the alces_command method
  # However as this is a private method, it has to use send
  #
  def test_command(command)
    double('TestDouble', alces: alces, raw_alces_command: command)
      .extend(Metalware::CommandHelpers::AlcesCommand)
      .send(:alces_command)
  end

  it 'errors if it contains brackets/ parentheses' do
    ['{}', '[]', '()'].each do |b|
      expect { test_command(b) }.to raise_error(Metalware::InvalidInput)
    end
  end

  it 'errors for other puncation as delimitors' do
    [';', ':', ',', '"', "'"].each do |p|
      cmd = "alces#{p}domain#{p}config"
      msg = "expected '#{p}' to raise InvalidInput error"
      expect do
        test_command(cmd)
      end.to raise_error(Metalware::InvalidInput), msg
    end
  end

  it 'does not error with period or white space delimitor' do
    expect { test_command('alces.domain.config') }.not_to raise_error
    expect { test_command('alces domain config') }.not_to raise_error
    expect { test_command('alces.domain config') }.not_to raise_error
  end

  it 'can not end in a delimitor' do
    expect do
      test_command('alces.domain.config.')
    end.to raise_error(Metalware::InvalidInput)
    expect do
      test_command('.alces.domain.config')
    end.to raise_error(Metalware::InvalidInput)
  end

  it 'can return the domain config' do
    expect(test_command('alces.domain.config')).to eq(alces.domain.config)
  end

  it 'treats the leading alces as optional' do
    expect(test_command('domain.config')).to eq(alces.domain.config)
  end

  it 'allows short name for alces' do
    expect(test_command('a.domain.config')).to eq(alces.domain.config)
    expect(test_command('alc.domain.config')).to eq(alces.domain.config)
  end

  it 'allows short name for nodes' do
    expect(test_command("alces.n.#{node}.name")).to eq(node)
  end

  it 'allows short name for groups' do
    expect(test_command("alces.g.#{group}.name")).to eq(group)
  end

  it 'allows short name for domain' do
    expect(test_command('alces.d.config')).to eq(alces.domain.config)
  end

  it 'allows short name for local' do
    expect(test_command('alces.l')).to eq(alces.local)
  end
end
