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

require 'build_methods/kickstarts/uefi'
require 'config'
require 'filesystem'
require 'file_path'

RSpec.describe Metalware::BuildMethods::Kickstarts::UEFI do
  let :config { Metalware::Config.new }
  let :node do
    node = Metalware::Node.new(config, 'nodeA01')
    allow(node).to receive(:build_method).and_return(:uefi)
    allow(node).to receive(:hexadecimal_ip).and_return('00000000')
    node
  end
  let :build_uefi { Metalware::BuildMethods::Kickstarts::UEFI.new(config, node) }
  let :file_path { Metalware::FilePath.new(config) }
  let :filesystem do
    FileSystem.setup(&:with_minimal_repo)
  end

  it 'contains the correct TEMPLATES list' do
    # The constant is set on initialize
    Metalware::BuildMethods::Kickstarts::UEFI.new(nil, nil)
    expect(Metalware::BuildMethods::Kickstarts::UEFI::TEMPLATES).to \
      eq([:kickstart, :'uefi-kickstart'])
  end

  it 'renders the pxelinux template with correct save_path' do
    inputs = {
      parameters: {},
      save_path: File.join(file_path.uefi_save, 'grub.cfg-00000000'),
    }
    expect(build_uefi).to receive(:render_template)
      .with(:'uefi-kickstart', **inputs)
    build_uefi.send(:render_pxelinux, {})
  end
end
