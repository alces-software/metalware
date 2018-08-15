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
require 'alces_utils'

RSpec.describe Metalware::Commands::Plugin::Activate do
  include AlcesUtils

  def run_plugin_activate(plugin_name)
    Metalware::Utils.run_command(
      Metalware::Commands::Plugin::Activate, plugin_name
    )
  end

  let(:filesystem) do
    FileSystem.setup do |fs|
      fs.with_minimal_repo
      fs.mkdir_p example_plugin_dir
    end
  end

  let(:example_plugin_dir) do
    File.join Metalware::FilePath.plugins_dir, example_plugin_name
  end
  let(:example_plugin_name) { 'example' }

  def example_plugin
    Metalware::Plugins.all.find do |plugin|
      plugin.name == example_plugin_name
    end
  end

  it 'switches the plugin to be activated' do
    filesystem.test do
      Metalware::Plugins.deactivate!(example_plugin_name)

      run_plugin_activate(example_plugin_name)

      expect(example_plugin).to be_activated
    end
  end

  it 'gives error if plugin does not exist' do
    filesystem.test do
      unknown_plugin_name = 'unknown_plugin'

      expect do
        AlcesUtils.redirect_std(:stderr) do
          run_plugin_activate(unknown_plugin_name)
        end
      end.to raise_error Metalware::MetalwareError,
                         "Unknown plugin: #{unknown_plugin_name}"
    end
  end
end
