#!/bin/bash

function datef() {
    # Output:
    # Sat Jun  8 20:29:08 2019
    date "+%a %b %-d %T %Y"
}

function createConfig() {
    cd "$APP_PERSIST_DIR/server" || exit


    if [ "$PASSWORD_PROTECTED" -eq 1 ]; then
        expect "$APP_PERSIST_DIR/build-client-full.exp" "$CLIENT_ID" "$CLIENT_PASSWORD"
    else
        easyrsa build-client-full "$CLIENT_ID" nopass  << EOF
yes
EOF
    fi

    mkdir -p $CLIENT_PATH
    cp "pki/inline/$CLIENT_ID.inline" ta.key $CLIENT_PATH
    cp "$APP_PERSIST_DIR/configs/client.ovpn" "$CLIENT_PATH"

    echo -e "\nremote $RESOLVED_HOST_ADDR $HOST_TUN_PORT" >> "$CLIENT_PATH/client.ovpn"
    # Embed client authentication files into config file
    cat "$CLIENT_PATH/$CLIENT_ID.inline" <(echo -e '<tls-auth>') \
        "$CLIENT_PATH/ta.key" <(echo -e '</tls-auth>') \
        >> "$CLIENT_PATH/client.ovpn"
    # Append client id info to the config
    echo ";client-id $CLIENT_ID" >> "$CLIENT_PATH/client.ovpn"
    echo "$CLIENT_PATH"
}

function generateClientConfig() {
    #case
    #first argument  = n  use second argument as CLIENT_ID
    #first argument = np use second argument as CLIENT_ID and set PASSWORD_PROTECTED as 1
    #default generate random CLIENT_ID
    FLAGS=$1
    case $FLAGS in
        n)
            CLIENT_ID="$2"
            ;;
        np)
            CLIENT_ID="$2"
            CLIENT_PASSWORD="$3"
            PASSWORD_PROTECTED=1
            ;;
        *)
            CLIENT_ID="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
            ;;
    esac
    CLIENT_PATH="$APP_PERSIST_DIR/clients/$CLIENT_ID"
    if [ -d "$CLIENT_PATH" ]; then
        echo "$(datef) Client with this id [$CLIENT_ID] already exists"
        exit 1
    else
        createConfig
    fi
    FILE_NAME="$CLIENT_ID.ovpn"
    FILE_PATH="$CLIENT_PATH/$FILE_NAME"
    echo "$(datef) $FILE_PATH file has been generated"
}

function removeConfig() {
    local CLIENT_ID="$1"
    cd "$APP_PERSIST_DIR/server" || exit
    easyrsa revoke "$CLIENT_ID" << EOF
yes
EOF
    easyrsa gen-crl
    cd "$APP_PERSIST_DIR" || exit
}

RESOLVED_HOST_ADDR=$(curl -s  ifconfig.co/ip)
