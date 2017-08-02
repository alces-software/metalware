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

require 'commands/each'
require 'spec_utils'
require 'ostruct'

RSpec.describe Metalware::Commands::Each, real_fs: true do
  before :each do
    SpecUtils.use_mock_genders(self)
    SpecUtils.use_unit_test_config(self)
  end

  def run_command_echo(node, group = false)
    opt = OpenStruct.new(group: group)
    $stdout = tmp = Tempfile.new('stdout')
    Metalware::Commands::Each.new([node, 'echo <%= alces.nodename %>'], opt)
    $stdout.flush
    $stdout.rewind
    $stdout.read
  ensure
    tmp.delete if tmp.respond_to?(:delete)
    $stdout = STDOUT
  end

  it 'runs the command on a single node' do
    output = run_command_echo('node01')
    expect(output).to eq("node01\n")
  end

  it 'runs the command over a group' do
    expected = (1..3).inject('') { |str, num| "#{str}testnode0#{num}\n" }
    output = run_command_echo('nodes', true)
    expect(output).to eq(expected)
  end
end
