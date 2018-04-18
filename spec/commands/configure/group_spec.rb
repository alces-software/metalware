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
require 'filesystem'
require 'group_cache'
require 'alces_utils'

RSpec.describe Metalware::Commands::Configure::Group do
  include AlcesUtils

  def run_configure_group(group)
    Metalware::Utils.run_command(
      Metalware::Commands::Configure::Group, group
    )
  end

  def update_cache
    Metalware::GroupCache.update { |c| yield c }
  end

  def new_cache
    Metalware::GroupCache.new
  end

  let(:filesystem) do
    FileSystem.setup(&:with_minimal_repo)
  end

  before do
    SpecUtils.mock_validate_genders_success(self)
  end

  it 'creates correct configurator' do
    filesystem.test do
      expect(Metalware::Configurator).to receive(:new).with(
        instance_of(Metalware::Namespaces::Alces),
        questions_section: :group,
        name: 'testnodes'
      ).and_call_original

      run_configure_group 'testnodes'
    end
  end

  describe 'recording groups' do
    context 'when `cache/groups.yaml` does not exist' do
      it 'creates it and inserts new primary group' do
        filesystem.test do
          run_configure_group 'testnodes'

          expect(new_cache.primary_groups).to eq [
            'testnodes',
            'orphan',
          ]
        end
      end
    end

    context 'when `cache/groups.yaml` exists' do
      it 'inserts primary group if new' do
        filesystem.test do
          update_cache { |c| c.add('first_group') }

          run_configure_group 'second_group'

          expect(new_cache.primary_groups).to eq [
            'first_group',
            'second_group',
            'orphan',
          ]
        end
      end

      it 'does nothing if primary group already presnt' do
        filesystem.test do
          ['first_group', 'second_group'].each do |group|
            update_cache { |c| c.add(group) }
          end

          run_configure_group 'second_group'

          expect(new_cache.primary_groups).to eq [
            'first_group',
            'second_group',
            'orphan',
          ]
        end
      end
    end
  end
end
