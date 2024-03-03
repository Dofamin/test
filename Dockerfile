FROM alpine:latest

LABEL maintainer="Roman Filippov <FilippovRV1@transport.mos.ru>"

# System settings. User normally shouldn't change these parameters
ENV APP_NAME OpenVpn
ENV APP_PERSIST_DIR /${APP_NAME}

# Configuration settings with default values
ENV NET_ADAPTER eth0
ENV HOST_TUN_PORT 1194

WORKDIR ${APP_PERSIST_DIR}

COPY scripts .
COPY configs .configs/

RUN apk add --no-cache openvpn easy-rsa bash netcat-openbsd zip curl dumb-init && \
    ln -s /usr/share/easy-rsa/easyrsa /usr/bin/easyrsa && \
    chmod +x ./*.sh

EXPOSE 1194/udp

# ENTRYPOINT [ "dumb-init", "./OpenVpn/start.sh" ]
CMD [ "bash" ]