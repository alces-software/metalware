
# frozen_string_literal: true

require 'namespaces/alces'
require 'config'
require 'spec_utils'

RSpec.describe Metalware::Namespaces::Node do
  let :config { Metalware::Config.new }
  let :alces { Metalware::Namespaces::Alces.new(config) }

  before :each { SpecUtils.use_mock_determine_hostip_script(self) }

  it 'has a hostip' do
    expect(alces.domain.hostip).to eq('1.2.3.4')
  end

  it 'has a hosts url' do
    url = 'http://1.2.3.4/metalware/system/hosts'
    expect(alces.domain.hosts_url).to eq(url)
  end

  it 'has a genders url' do
    url = 'http://1.2.3.4/metalware/system/genders'
    expect(alces.domain.genders_url).to eq(url)
  end
end
