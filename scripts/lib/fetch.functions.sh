#==============================================================================
# Copyright (C) 2007-2015 Stephen F. Norledge and Alces Software Ltd.
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
fetch_dist() {
    local name=$1
    # XXX - compare md5?
    if [ ! -f "${dep_src}/${name}.tar.gz" ]; then
        curl -# -L ${dist_url}/${os}/${name}.tar.gz > "${dep_src}/${name}.tar.gz"
    else
        doing 'Detect'
        say_done $?
    fi
}

fetch_source() {
    local url=$1
    local file=$2
    # XXX - compare md5?
    if [ ! -f "${dep_src}/${file}" ]; then
        curl -# -L "$url" > "${dep_src}/${file}"
    else
        doing 'Detect'
        say_done $?
    fi
}
