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

require 'underware/constants'
require 'underware/hash_mergers/underware_recursive_open_struct'

module Metalware
  module Constants
    METALWARE_INSTALL_PATH =
      File.absolute_path(File.join(File.dirname(__FILE__), '..'))

    METALWARE_DATA_PATH = Underware::Constants::METALWARE_DATA_PATH
    CACHE_PATH = File.join(METALWARE_DATA_PATH, 'cache')
    RENDERED_DIR_PATH = File.join(METALWARE_DATA_PATH, 'rendered')
    STAGING_DIR_PATH = File.join(METALWARE_DATA_PATH, 'staging')
    STAGING_MANIFEST_PATH = File.join(CACHE_PATH, 'staging-manifest.yaml')

    HUNTER_PATH = File.join(Underware::Constants::NAMESPACE_DATA_PATH, 'hunter.yaml')

    EVENTS_DIR_PATH = Underware::Constants::EVENTS_DIR_PATH

    DHCPD_HOSTS_PATH = '/etc/dhcp/dhcpd.hosts'

    HOSTS_PATH = '/etc/hosts'

    UEFI_SAVE_PATH = '/var/lib/tftpboot/efi'

    NAMED_TEMPLATE_PATH = File.join(
      METALWARE_INSTALL_PATH, 'templates/named.conf.erb'
    )
    METALWARE_NAMED_PATH = '/etc/named/metalware.conf'
    VAR_NAMED_PATH = '/var/named'

    BUILD_POLL_SLEEP = 10

    LOG_SEVERITY = 'INFO'
  end
end
