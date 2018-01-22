#==============================================================================
# Copyright (C) 2015 Stephen F. Norledge and Alces Software Ltd.
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
install_runtime_prerequisites() {
    # ruby: openssl readline zlib libffi
    # hunter: libpcap
    # console/ipmi/power: ipmitool
    yum -e0 -y install openssl readline zlib libffi && \
        yum -e0 -y install libpcap && \
        yum -e0 -y install ipmitool && \
        yum -e0 -y install gettext && \
        yum -e0 -y install epel-release && \
        yum -e0 -y install jq && \
        yum -e0 -y install syslinux && \
        yum -e0 -y install bind bind-utils && \
        yum -e0 -y install git
}

install_base_prerequisites() {
    yum -e0 -y install lsof
}

install_build_prerequisites() {
    # ruby: openssl readline zlib libffi
    # hunter: libpcap
    # rugged: cmake libcurl-devel libssh2-devel gmp-devel
    # ruby-libvirt: libvirt-devel gnutls-utils libvirt-client
    yum -e0 -y groupinstall "Development Tools" && \
        yum -e0 -y install openssl-devel readline-devel zlib-devel libffi-devel && \
        yum -e0 -y install libpcap-devel && \
        yum -e0 -y install cmake libcurl-devel libssh2-devel gmp-devel && \
        yum -e0 -y install libvirt-devel gnutls-utils libvirt-client
}
