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
  let(:updater) { described_class.new(hunter_file) }
  let!(:output) { class_spy(Metalware::Output).as_stubbed_const }

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
      let(:node_name) { 'somenode01' }
      let(:other_node) { 'somenode02' }
      let(:initial_mac) { 'some_mac_address' }
      let(:new_mac) { 'another_mac_address' }

      before do
        Metalware::Data.dump(
          hunter_file,
          node_name.to_sym => initial_mac
        )
      end

      context 'when updating a nodes mac address' do
        before { updater.add(node_name, new_mac) }

        it 'issues an error message' do
          expect(output).to have_received(:stderr).once
          expect(output).to have_received(:stderr)
            .with(/Replacing.*#{node_name}.*#{initial_mac}/)
        end

        it 'updates the nodes mac address' do
          expect(hunter_yaml[node_name.to_sym]).to eq(new_mac)
        end

        it 'can re-assign the old mac to another node' do
          updater.add(other_node, initial_mac)
          expect(output).not_to have_received(:stderr)
            .with(/#{other_node}/)
          expect(hunter_yaml[other_node.to_sym]).to eq(initial_mac)
        end
      end

      context 'when assigning a new node to an existing mac' do
        before { updater.add(other_node, initial_mac) }

        it 'issues an error message' do
          expect(output).to have_received(:stderr).once
          expect(output).to have_received(:stderr)
            .with(/Replacing.*#{initial_mac}.*#{node_name}/)
        end

        it 'reassigns the mac in the cache' do
          expect(hunter_yaml).to eq(other_node.to_sym => initial_mac)
        end

        it 'does not warn when the old node gets a new mac' do
          updater.add(node_name, new_mac)
          expect(output).not_to have_received(:stderr)
            .with(/#{new_mac}/)
        end
      end
    end

    context 'when hunter file does not exist yet' do
      before do
        File.delete(hunter_file)
      end

      it 'creates it first' do
        updater.add('somenode01', 'some_mac_address')
        expect(hunter_yaml).to eq(somenode01: 'some_mac_address')
      end
    end
  end
end
