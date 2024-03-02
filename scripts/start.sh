#!/bin/bash
source ./functions.sh

if [[ $? -ne 0 ]] ; then
    exit 1
fi

mkdir -p /dev/net

if [ ! -c /dev/net/tun ]; then
    echo "$(datef) Creating tun/tap device."
    mknod /dev/net/tun c 10 200
fi

cd "$APP_PERSIST_DIR" || exit

# Generate certs if folder don't exist
if [ ! -f "$APP_PERSIST_DIR/server/pki" ]; then
        mkdir -p "${APP_PERSIST_DIR}/server"
        cd "${APP_PERSIST_DIR}/server" || exit
        easyrsa init-pki
        easyrsa gen-dh
        # DH parameters of size 2048 created at /usr/share/easy-rsa/pki/dh.pem
        # Copy DH file
        cp pki/dh.pem /etc/openvpn
        easyrsa build-ca nopass <<- EOF

EOF
        # CA creation complete and you may now import and sign cert requests.
        # Your new CA certificate file for publishing is at:
        # /opt/OpenVpn_data/pki/ca.crt
        easyrsa gen-req MyReq nopass << EOF2

EOF2
        # Keypair and certificate request completed. Your files are:
        # req: /opt/OpenVpn_data/pki/reqs/Server.req
        # key: /opt/OpenVpn_data/pki/private/Server.key
        easyrsa sign-req server MyReq << EOF3
yes
EOF3
        # Certificate created at: /opt/OpenVpn_data/pki/issued/Server.crt
        openvpn --genkey --secret ta.key << EOF4
yes
EOF4
        easyrsa gen-crl
        # Copy server keys and certificates
        cp pki/dh.pem pki/ca.crt pki/issued/MyReq.crt pki/private/MyReq.key pki/crl.pem ta.key /etc/openvpn
fi


cd "$APP_INSTALL_PATH" || exit
openvpn --config "${APP_PERSIST_DIR}/server/server.conf" & tail -f /dev/null
