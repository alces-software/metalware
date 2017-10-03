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

require 'hash_mergers/metal_recursive_open_struct'

module Metalware
  module Constants
    METALWARE_INSTALL_PATH = File.absolute_path(File.join(File.dirname(__FILE__), '..'))
    METAL_EXECUTABLE_PATH = File.join(METALWARE_INSTALL_PATH, 'bin/metal')

    METALWARE_CONFIGS_PATH = File.join(METALWARE_INSTALL_PATH, 'etc')
    DEFAULT_CONFIG_PATH = File.join(METALWARE_CONFIGS_PATH, 'config.yaml')

    METALWARE_DATA_PATH = '/var/lib/metalware'
    CACHE_PATH = File.join(METALWARE_DATA_PATH, 'cache')
    HUNTER_PATH = File.join(CACHE_PATH, 'hunter.yaml')
    GROUP_CACHE_PATH = File.join(CACHE_PATH, 'groups.yaml')
    INVALID_RENDERED_GENDERS_PATH = File.join(CACHE_PATH, 'invalid.genders')
    # XXX Following needs to actually be created somewhere.
    GUI_CREDENTIALS_PATH = File.join(CACHE_PATH, 'credentials.yaml')

    MAXIMUM_RECURSIVE_CONFIG_DEPTH = 10

    NODEATTR_COMMAND = 'nodeattr'

    SERVER_CONFIG_PATH = File.join(METALWARE_DATA_PATH, 'rendered/system/server.yaml')
    GENDERS_PATH = File.join(METALWARE_DATA_PATH, 'rendered/system/genders')
    HOSTS_PATH = '/etc/hosts'

    UEFI_SAVE_PATH = '/var/lib/tftpboot/efi'

    NAMED_TEMPLATE_PATH = File.join(METALWARE_INSTALL_PATH, 'templates/named.conf.erb')
    METALWARE_NAMED_PATH = '/etc/named/metalware.conf'
    VAR_NAMED_PATH = '/var/named'

    CONFIGURE_SECTIONS = [:domain, :group, :node, :self].freeze

    HASH_MERGER_DATA_STRUCTURE =
      Metalware::HashMergers::MetalRecursiveOpenStruct
  end
end
