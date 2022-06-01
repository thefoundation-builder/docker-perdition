#FROM alpine
#FROM golang:1.17-alpine
FROM golang:alpine
RUN apk --no-cache upgrade && apk --no-cache add perdition  iproute2 socat bash openssl  curl
RUN uname -a |grep aarch64 || go install -v github.com/wzshiming/bridge/cmd/bridge@latest
RUN uname -a |grep aarch64 && link=$(wget -O- https://github.com/wzshiming/bridge/releases|grep bridge_linux_arm64 |grep href|head -n1|cut -d'"' -f2) && bash -c '[[ -z "'$link'" ]] || wget -c https://github.com/"'$link'" -O /bridge'
RUN /bin/bash 'test -e /bridge && chmod +x /bridge && ln -s /bridge /usr/bin/bridge' || true
RUN which bridge
COPY bild/perdition-single.sh /perdition-single.sh
COPY bild/tormail_subdomain.sh /tormail_subdomain.sh
