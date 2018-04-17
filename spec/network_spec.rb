
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

require 'network'

RSpec.describe Metalware::Network do
  describe '#valid_interface?' do
    before(:each) do
      expect(NetworkInterface).to receive(:interfaces).and_return(
        ['eth0', 'eth1']
      )
    end

    it 'returns true for interface name in list of interfaces' do
      expect(described_class.valid_interface?('eth1')).to be true
    end

    it 'returns false for interface name not in list of interfaces' do
      expect(described_class.valid_interface?('eth3')).to be false
    end
  end
end
