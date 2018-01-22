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
install_dist() {
    local name=$1
    doing 'Install'
    tar -C "${target}" -xzf "${dep_src}/$name.tar.gz"
    say_done $?
}

install_certs() {
    export CA_DIR=/var/lib/metalware/certs
    mkdir -p $CA_DIR

    if [[ ! -f $CA_DIR/cakey.pem ]]; then
      configure_certificate_authority
    fi

    if [[ ! -f $CA_DIR/server-key.pem ]]; then
      configure_server_authority
    fi

    if [[ ! -f $CA_DIR/clientkey.pem ]]; then
      configure_client_certificate
    fi
}

configure_certificate_authority() {
    certtool --generate-privkey > $CA_DIR/cakey.pem
    cat << EOF > $CA_DIR/ca.info
cn = Alces Software
ca
cert_signing_key
EOF
    certtool --generate-self-signed \
             --load-privkey $CA_DIR/cakey.pem \
             --template $CA_DIR/ca.info \
             --outfile $CA_DIR/cacert.pem
    cp $CA_DIR/cacert.pem /etc/pki/CA/
}

configure_server_authority() {
    certtool --generate-privkey > $CA_DIR/server-key.pem
    cat << EOF > $CA_DIR/server.info
organization = Alces Software
cn = Libvirt
tls_www_server
encryption_key
signing_key
EOF
    certtool --generate-certificate \
             --load-privkey $CA_DIR/server-key.pem \
             --load-ca-certificate $CA_DIR/cacert.pem \
             --load-ca-privkey $CA_DIR/cakey.pem \
             --template $CA_DIR/server.info \
             --outfile $CA_DIR/server-cert.pem
}

configure_client_certificate() {
    certtool --generate-privkey > $CA_DIR/clientkey.pem
    cat << EOF > $CA_DIR/client.info
organization = Alces Software
cn = controller
tls_www_client
encryption_key
signing_key
EOF
    certtool --generate-certificate \
             --load-privkey $CA_DIR/clientkey.pem \
             --load-ca-certificate $CA_DIR/cacert.pem \
             --load-ca-privkey $CA_DIR/cakey.pem \
             --template $CA_DIR/client.info \
             --outfile $CA_DIR/clientcert.pem
    mkdir -p /etc/pki/libvirt/private
    cp $CA_DIR/clientkey.pem /etc/pki/libvirt/private/
    cp $CA_DIR/clientcert.pem /etc/pki/libvirt/
}
