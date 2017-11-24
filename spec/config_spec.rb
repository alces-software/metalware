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

require 'yaml'

require 'config'
require 'exceptions'
require 'constants'
require 'spec_utils'

RSpec.describe Metalware::Config do
  it 'uses default config file' do
    expect(YAML).to receive(:load_file).with(
      Metalware::Constants::DEFAULT_CONFIG_PATH
    )
    Metalware::Config.new
  end

  it 'can have default values retrieved' do
    FileSystem.root_setup do |fs|
      fs.with_metal_config_fixture('configs/empty.yaml')
    end
    config = Metalware::Config.new
    expect(config.built_nodes_storage_path).to eq('/var/lib/metalware/cache/built-nodes')
    expect(config.rendered_files_path).to eq('/var/lib/metalware/rendered')
    expect(config.build_poll_sleep).to eq(10)
  end

  it 'can have set values retrieved over defaults' do
    FileSystem.root_setup do |fs|
      fs.with_metal_config_fixture('configs/non-empty.yaml')
    end
    config = Metalware::Config.new
    expect(config.built_nodes_storage_path).to eq('/built/nodes')
    expect(config.rendered_files_path).to eq('/rendered/files')
    expect(config.build_poll_sleep).to eq(5)
  end

  describe '#cache' do
    def expect_return_cache_config(**opts)
      cache_config = Metalware::Config.new
      Metalware::Config.cache = cache_config
      expect(Metalware::Config.cache(**opts)).to eq(cache_config)
    end

    context 'without new_if_missing flag' do
      it 'error if the cache is not set' do
        expect do
          Metalware::Config.cache
        end.to raise_error(Metalware::ConfigCacheError)
      end

      it 'returns the cached config' do
        expect_return_cache_config
      end
    end

    context 'with new_if_missing flag' do
      it 'returns a new Config if cache is not set' do
        config = Metalware::Config.cache(new_if_missing: true)
        expect(config).to be_a(Metalware::Config)
      end

      it 'returns the cached config' do
        expect_return_cache_config(new_if_missing: true)
      end
    end
  end
end
