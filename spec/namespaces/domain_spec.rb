
# frozen_string_literal: true

require 'shared_examples/hash_merger_namespace'
require 'namespaces/alces'
require 'spec_utils'

RSpec.describe Metalware::Namespaces::Domain do
  include AlcesUtils

  subject { alces.domain }

  include_examples Metalware::Namespaces::HashMergerNamespace

  before { use_mock_determine_hostip_script }

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
