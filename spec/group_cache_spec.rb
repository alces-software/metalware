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

require 'config'
require 'group_cache'
require 'filesystem'

RSpec.describe Metalware::GroupCache do
  let :config { Metalware::Config.new }
  let :cache { Metalware::GroupCache.new(config) }

  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_group_cache_fixture('cache/groups.yaml')
    end
  end

  describe '#group?' do
    it 'checks if a group has been configured' do
      filesystem.test do
        expect(cache.group?('testnodes')).to eq(true)
        expect(cache.group?('missing_group')).to eq(false)
      end
    end
  end

  describe '#add' do
    it 'adds a new group' do
      filesystem.test do
        expect(cache.group?('new_group')).to eq(false)
        cache.add('new_group')
        expect(cache.group?('new_group')).to eq(true)
      end
    end

    it 'ignores groups that have already been added' do
      filesystem.test do
        expect(cache.group?('testnodes')).to eq(true)
        number_groups = cache.primary_groups.length
        cache.add('testnodes')
        expect(cache.primary_groups.length).to eq(number_groups)
      end
    end
  end

  describe '#remove' do
    it 'removes a group' do
      filesystem.test do
        expect(cache.group?('testnodes')).to eq(true)
        cache.remove('testnodes')
        expect(cache.group?('testnodes')).to eq(false)
      end
    end
  end
end
