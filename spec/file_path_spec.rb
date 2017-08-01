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
require 'constants'
require 'file_path'

RSpec.describe Metalware::Network do
  let :config { Metalware::Config.new }

  describe 'dynamic constant paths' do
    let :file_path { Metalware::FilePath.new(config) }

    it 'defines a constant file path' do
      expect(file_path.metalware_data).to eq(Metalware::Constants::METALWARE_DATA_PATH)
    end

    it 'does not define non-paths' do
      expect(file_path.respond_to?(:nodeattr_command)).to eq(false)
    end
  end
end