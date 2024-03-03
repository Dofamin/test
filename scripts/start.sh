#!/bin/bash
source ./functions.sh

if [[ $? -ne 0 ]] ; then
    exit 1
fi

HOST_ADDR=$(ip route get 1.2.3.4 | awk '{print $7}')

mkdir -p /dev/net

if [ ! -c /dev/net/tun ]; then
    echo "$(datef) Creating tun/tap device."
    mknod /dev/net/tun c 10 200
fi

cd "$APP_PERSIST_DIR" || exit

# Generate certs if folder don't exist
if [ ! -d "$APP_PERSIST_DIR/server/pki" ]; then
        mkdir -p "${APP_PERSIST_DIR}/server"
        cd "${APP_PERSIST_DIR}/server" || exit
        easyrsa --batch init-pki
        easyrsa --batch gen-dh
        easyrsa build-ca nopass <<- EOF

EOF
        easyrsa gen-req vpn-server nopass << EOF1

EOF1
        easyrsa sign-req server vpn-server << EOF2
yes
EOF2
        openvpn --genkey secret ta.key<< EOF3
yes
EOF3
        easyrsa gen-crl
fi

if [ "$1" == "" ];
then
cp -anf /OpenVpn/* /OpenVpn_data/
sed -i "/local/c\local $HOST_ADDR" "${APP_PERSIST_DIR}/configs/server.conf"
openvpn --config "${APP_PERSIST_DIR}/configs/server.conf" --dev tun --tls-server & tail -f /dev/null
else
cp -anf /OpenVpn/* /OpenVpn_data/
sed -i "/local/c\local $HOST_ADDR" "${APP_PERSIST_DIR}/configs/server.conf"
exec "$1"
fi