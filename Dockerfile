FROM alpine:latest

LABEL maintainer="Roman Filippov <FilippovRV1@transport.mos.ru>"

# System settings. User normally shouldn't change these parameters
ENV APP_NAME OpenVpn
ENV APP_INSTALL_PATH /opt/${APP_NAME}
ENV APP_PERSIST_DIR /opt/${APP_NAME}_data

# Configuration settings with default values
ENV NET_ADAPTER eth0
ENV HOST_ADDR ""
ENV HOST_TUN_PORT 1194
ENV HOST_CONF_PORT 80

WORKDIR ${APP_INSTALL_PATH}

COPY scripts .
COPY config ./config
COPY VERSION ./config

RUN apk add --no-cache openvpn easy-rsa bash netcat-openbsd zip curl dumb-init && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/bin/easyrsa && \
    mkdir -p ${APP_PERSIST_DIR} && \
    cp config/server.conf /etc/openvpn/server.conf

EXPOSE 1194/udp

ENTRYPOINT [ "dumb-init", "./start.sh" ]
CMD [ "" ]