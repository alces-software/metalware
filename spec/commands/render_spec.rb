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

require 'timeout'

require 'commands/render'
require 'spec_utils'
require 'config'
require 'tempfile'

RSpec.describe Metalware::Commands::Render do
  include AlcesUtils

  AlcesUtils.mock self, :each { with_blank_config_and_answer(alces.domain) }

  context 'and with --strict option' do
    AlcesUtils.mock self, :each { mock_strict(true) }

    let :template { '<%= domain.config.missing %>' }

    let :template_file do
      f = Tempfile.new('template')
      f.write(template)
      f.rewind
      f
    end

    after :each do
      template_file.unlink
    end

    it 'raises StrictWarningError when a parameter is missing' do
      expect do
        AlcesUtils.redirect_std(:stderr) do
          Metalware::Utils.run_command(
            Metalware::Commands::Render, template_file.path, strict: 'mocked'
          )
        end
      end.to raise_error(Metalware::StrictWarningError)
    end
  end
end
