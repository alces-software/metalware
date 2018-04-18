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
require 'filesystem'
require 'file_path'
require 'alces_utils'

RSpec.describe Metalware::BuildMethods::Kickstarts::UEFI do
  include AlcesUtils

  before do
    FileSystem.root_setup(&:with_minimal_repo)
  end

  let(:node_name) { 'nodeA01' }
  let(:node) { alces.nodes.find_by_name node_name }

  AlcesUtils.mock self, :each do
    n = mock_node node_name
    allow(n).to receive(:hexadecimal_ip).and_return('00000000')
    config(n, build_method: :'uefi-kickstart')
  end

  it 'renders the pxelinux template with correct save_path' do
    save_path = File.join(Metalware::FilePath.uefi_save, 'grub.cfg-00000000')
    FileUtils.mkdir(File.dirname(save_path))
    node.build_method.start_hook
    expect(File.exist?(save_path)).to eq(true)
  end
end
