
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

RSpec.describe Metalware::Templating::MagicNamespace do
  # Note: many `MagicNamespace` features are tested at the `Templater` level
  # instead.

  describe '#groups' do
    subject do
      Metalware::Templating::MagicNamespace.new(
        config: Metalware::Config.new
      )
    end

    it 'calls the passed block with a group namespace for each primary group' do
      FileSystem.test do |fs|
        fs.with_groups_cache_fixture('cache/groups.yaml')

        group_names = []
        subject.groups do |group|
          expect(group).to be_a(Metalware::Templating::GroupNamespace)
          group_names << group.name
        end

        expect(group_names).to eq(['some_group', 'testnodes'])
      end
    end
  end
end
