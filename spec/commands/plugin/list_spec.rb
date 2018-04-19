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

RSpec.describe Metalware::Commands::Plugin::List do
  include AlcesUtils

  def run_plugin_list
    Metalware::Utils.run_command(
      Metalware::Commands::Plugin::List
    )
  end

  let(:filesystem) do
    FileSystem.setup do |fs|
      fs.with_minimal_repo
      fs.mkdir_p example_plugin_dir_1
      fs.mkdir_p example_plugin_dir_2
      fs.touch junk_other_plugins_dir_file
    end
  end

  let(:example_plugin_dir_1) do
    File.join Metalware::FilePath.plugins_dir, 'example01'
  end
  let(:example_plugin_dir_2) do
    File.join Metalware::FilePath.plugins_dir, 'example02'
  end
  let(:junk_other_plugins_dir_file) do
    File.join Metalware::FilePath.plugins_dir, 'junk'
  end

  it 'outputs line for each plugin subdirectory' do
    filesystem.test do
      stdout = AlcesUtils.redirect_std(:stdout) do
        run_plugin_list
      end[:stdout].read

      expect(stdout).to match(/example01.*\nexample02.*\n/)
    end
  end

  it 'specifies whether each plugin is activated in output' do
    filesystem.test do |_fs|
      Metalware::Plugins.activate!('example01')
      Metalware::Plugins.deactivate!('example02')

      stdout = AlcesUtils.redirect_std(:stdout) do
        run_plugin_list
      end[:stdout].read

      activated = '[ACTIVATED]'.green
      deactivated = '[DEACTIVATED]'.red
      expect(stdout).to eq "example01 #{activated}\nexample02 #{deactivated}\n"
    end
  end
end
