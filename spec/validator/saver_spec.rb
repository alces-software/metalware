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

require 'filesystem'
require 'config'
require 'validator/saver'
require 'validator/loader'

RSpec.describe Metalware::Validator::Saver do
  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_groups_cache_fixture('cache/groups.yaml')
    end
  end

  let :config do
    Metalware::Config.new
  end

  let :saver { Metalware::Validator::Saver.new(config) }
  let :loader { Metalware::Validator::Loader.new(config) }

  def save_data(method, data, &test_block)
    filesystem.test do |_fs|
      saver.send(method).save(data)
      yield
    end
  end

  it 'saves an updated group cache' do
    data = { primary_group: 'new_group' }
    save_data(:groups_cache, data) do
      expect(loader.groups_cache).to eq(data)
    end
  end
end
