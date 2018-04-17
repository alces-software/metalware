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

require 'tempfile'

require 'hunter_updater'
require 'output'

RSpec.describe Metalware::HunterUpdater do
  let(:hunter_file) { Tempfile.new.path }
  let(:updater) { Metalware::HunterUpdater.new(hunter_file) }

  def hunter_yaml
    Metalware::Data.load(hunter_file)
  end

  describe '#add' do
    it 'adds given node name and MAC address pairs to hunter file' do
      updater.add('somenode01', 'some_mac_address')
      expect(hunter_yaml).to eq(somenode01: 'some_mac_address')

      updater.add('somenode02', 'another_mac_address')
      expect(hunter_yaml).to eq(somenode01: 'some_mac_address',
                                somenode02: 'another_mac_address')
    end

    context 'with existing hunter content' do
      before :each do
        Metalware::Data.dump(hunter_file, somenode01: 'some_mac_address')
      end

      it 'outputs info if replacing node name' do
        # Replaces existing entry with node name.
        expect(Metalware::Output).to receive(:stderr).with(
          /Replacing.*somenode01.*some_mac_address/
        )
        updater.add('somenode01', 'another_mac_address')
        expect(hunter_yaml).to eq(somenode01: 'another_mac_address')

        # Does not replace when new node name.
        expect(Metalware::Output).not_to receive(:stderr)
        updater.add('somenode02', 'some_mac_address')
      end

      it 'outputs info if replacing MAC address' do
        # Replaces existing entry with MAC address.
        expect(Metalware::Output).to receive(:stderr).with(
          /Replacing.*some_mac_address.*somenode01/
        )
        updater.add('somenode02', 'some_mac_address')
        expect(hunter_yaml).to eq(somenode02: 'some_mac_address')

        # Does not replace when new MAC address.
        expect(Metalware::Output).not_to receive(:stderr)
        updater.add('somenode01', 'another_mac_address')
      end
    end

    context 'when hunter file does not exist yet' do
      before :each do
        File.delete(hunter_file)
      end

      it 'creates it first' do
        updater.add('somenode01', 'some_mac_address')
        expect(hunter_yaml).to eq(somenode01: 'some_mac_address')
      end
    end
  end
end
