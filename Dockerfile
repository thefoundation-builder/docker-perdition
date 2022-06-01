#FROM alpine
#FROM golang:1.17-alpine
FROM golang:alpine
RUN apk --no-cache upgrade && apk --no-cache add perdition  iproute2 socat bash openssl  curl
RUN uname -a |grep aarch64 || go install -v github.com/wzshiming/bridge/cmd/bridge@latest
COPY build/install_bridge.sh /tmp/installbridge.sh
RUN uname -a |grep aarch64 && /bin/bash /tmp/installbridge.sh || true
RUN /bin/bash 'test -e /bridge && chmod +x /bridge && ln -s /bridge /usr/bin/bridge' || true
RUN which bridge
COPY build/perdition-single.sh /perdition-single.sh
COPY build/tormail_subdomain.sh /tormail_subdomain.sh
