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
  it 'can have default values retrieved' do
    FileSystem.root_setup { |fs| fs.with_clone_fixture('configs/empty.yaml') }
    config_file = SpecUtils.fixtures_config('empty.yaml')
    config = Metalware::Config.new(config_file)
    expect(config.built_nodes_storage_path).to eq('/var/lib/metalware/cache/built-nodes')
    expect(config.rendered_files_path).to eq('/var/lib/metalware/rendered')
    expect(config.build_poll_sleep).to eq(10)
  end

  it 'can have set values retrieved over defaults' do
    FileSystem.root_setup do |fs|
      fs.with_clone_fixture('configs/non-empty.yaml')
    end
    config_file = SpecUtils.fixtures_config('non-empty.yaml')
    config = Metalware::Config.new(config_file)
    expect(config.built_nodes_storage_path).to eq('/built/nodes')
    expect(config.rendered_files_path).to eq('/rendered/files')
    expect(config.build_poll_sleep).to eq(5)
  end

  it 'raises if config file does not exist' do
    config_file = File.join(FIXTURES_PATH, 'configs/non-existent.yaml')
    expect do
      Metalware::Config.new(config_file)
    end.to raise_error(Metalware::MetalwareError)
  end

  it 'uses default config file if none given' do
    expect(YAML).to receive(:load_file).with(
      Metalware::Constants::DEFAULT_CONFIG_PATH
    )

    Metalware::Config.new(nil)
  end
end
