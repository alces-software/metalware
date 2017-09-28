
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

require 'templating/group_namespace'
require 'filesystem'
require 'spec_utils'

RSpec.describe Metalware::Templating::GroupNamespace do
  subject do
    Metalware::Templating::GroupNamespace.new(
      Metalware::Config.new,
      group_name
    )
  end

  let :group_name { 'testnodes' }

  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_repo_fixtures('repo')
      fs.with_answer_fixtures('answers/group_namespace_tests')
    end
  end

  describe '#name' do
    it 'returns the name of the group' do
      filesystem.test do
        expect(subject.name).to eq(group_name)
      end
    end
  end

  describe '#answers' do
    it 'returns the group answers merged into the domain answers' do
      # Turns off answer file validation as they do not match the configure.yaml
      allow_any_instance_of(Metalware::Validation::Answer).to \
        receive(:success?).and_return(true)

      filesystem.test do
        expect(subject.answers.to_h).to eq(domain_value: 'domain_value',
                                           overriding_domain_value: 'testnodes_value',
                                           genders_host_range: 'node0[10-20]')
      end
    end
  end

  describe '#nodes' do
    it 'calls the block with templater config for each node in the group' do
      SpecUtils.use_mock_genders(self, genders_file: 'genders/group_namespace')

      filesystem.test do
        node_names = []
        some_repo_values = []

        subject.nodes do |node|
          node_names << node.alces.nodename
          some_repo_values << node.some_repo_value
        end

        expect(node_names).to eq([
                                   'node01', 'node05', 'node10', 'node11', 'node12'
                                 ])

        expected_repo_values = (['repo_value'] * 5).tap do |expected|
          expected[1] = 'value_just_for_node05'
        end
        expect(some_repo_values).to eq(expected_repo_values)
      end
    end
  end
end
