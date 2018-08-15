
# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

require 'spec_utils'
require 'dependency_specifications'
require 'namespaces/alces'

RSpec.describe Metalware::DependencySpecifications do
  subject do
    described_class.new(alces)
  end

  let(:alces) { Metalware::Namespaces::Alces.new }

  before do
    SpecUtils.use_mock_genders(self)
    allow_any_instance_of(Metalware::Namespaces::Node).to \
      receive(:group).and_return(double('group', name: 'testnodes'))
  end

  describe '#for_node_in_configured_group' do
    it 'returns correct hash, including node primary group' do
      expect(subject.for_node_in_configured_group('testnode01')).to eq(
        repo: ['configure.yaml'],
        configure: ['domain.yaml', 'groups/testnodes.yaml'],
        optional: {
          configure: ['nodes/testnode01.yaml'],
        }
      )
    end

    it 'raises if node not in configured primary group' do
      expect do
        subject.for_node_in_configured_group('node_not_in_configured_group')
      end.to raise_error Metalware::NodeNotInGendersError
    end
  end
end
