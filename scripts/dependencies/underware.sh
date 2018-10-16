#==============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd.
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

detect_underware() {
    [ -d "/opt/underware" ]
}

fetch_underware() {
    # No-op function required as `scripts/install` will call this, but we just
    # want to fetch and install Underware with a single command in the usual
    # way (below).
    :
}

install_underware() {
    title "Installing Underware"

    # Will be installed with same arguments as provided to
    # `metalware-installer`, due to variables exported in `scripts/install`.
    curl -sL http://git.io/underware-installer | /bin/bash
}
