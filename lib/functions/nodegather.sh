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
nodegather() {
  if [ -z $1 ]; then
    echo "Please pass genders compatible node string as first parameter" >&2
    exit 1
  fi
  if ((nodeattr -c $1) > /dev/null 2>&1); then
    nodeattr -c $1 | sed 's/,/\n/g'
  else
    echo "Please pass vaild genders compatible node string as first parameter" >&2
    exit 1
  fi
}
