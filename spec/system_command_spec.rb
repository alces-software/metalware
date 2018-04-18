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

require 'system_command'

RSpec.describe Metalware::SystemCommand do
  it 'runs the command and returns stdout' do
    expect(
      described_class.run('echo something')
    ).to eq "something\n"
  end

  context 'when command fails' do
    it 'raises' do
      expect do
        described_class.run('false')
      end.to raise_error Metalware::SystemCommandError
    end

    it 'formats the error displayed to users when `format_error` is true' do
      begin
        described_class.run('false', format_error: true)
      rescue Metalware::SystemCommandError => e
        expect(e.message).to match(/produced error/)
      end
    end

    it 'does not format the error when `format_error` is false' do
      begin
        described_class.run('false', format_error: false)
      rescue Metalware::SystemCommandError => e
        expect(e.message).not_to match(/produced error/)
      end
    end
  end
end
