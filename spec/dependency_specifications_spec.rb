
# frozen_string_literal: true

require 'spec_utils'
require 'dependency_specifications'

RSpec.describe Metalware::DependencySpecifications, real_fs: true do
  subject do
    Metalware::DependencySpecifications.new(Metalware::Config.new)
  end

  before do
    SpecUtils.use_mock_genders(self)
  end

  describe '#for_node_in_configured_group' do
    it 'returns correct hash, including node primary group' do
      expect(subject.for_node_in_configured_group('testnode01')).to eq(
        repo: ['configure.yaml'],
        configure: ['domain.yaml', 'groups/testnodes.yaml']
      )
    end

    it 'raises if node not in configured primary group' do
      expect do
        subject.for_node_in_configured_group('node_not_in_configured_group')
      end.to raise_error Metalware::NodeNotInGendersError
    end
  end
end
