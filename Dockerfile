FROM ubuntu:bionic
#FROM ubuntu:20.04

RUN apt-get update && apt-get -y install iproute2 net-tools imapproxy perdition curl bash socat openssl && apt-get -y clean all 

#FROM alpine
#RUN apk --no-cache upgrade && apk --no-cache add perdition  iproute2 socat bash openssl  curl

#FROM golang:1.17-alpine
##FROM golang:alpine
##RUN uname -a |grep aarch64 || go install -v github.com/wzshiming/bridge/cmd/bridge@latest
##COPY build/install_bridge.sh /tmp/installbridge.sh
##RUN uname -a |grep aarch64 && /bin/bash /tmp/installbridge.sh || true
##RUN /bin/bash 'test -e /bridge && chmod +x /bridge && ln -s /bridge /usr/bin/bridge' || true
##RUN which bridge
COPY build/perdition-single.sh /perdition-single.sh
##COPY build/tormail_subdomain.sh /tormail_subdomain.sh
EXPOSE 143 993 1143 2143 4190 4191 4192

LABEL org.opencontainers.image.source="https://gitlab.com/the-foundation/docker-perdition" 
LABEL org.opencontainers.image.description="docker-perdition multiarch ubuntu version . over 100MB"
LABEL org.opencontainers.image.created=
LABEL org.opencontainers.image.authors="The Foundation <no@mail.lan>"
LABEL org.opencontainers.image.url=https://the-foundation.gitlab.io/
LABEL org.opencontainers.image.documentation=https://gitlab.com/the-foundation/docker-perdition
LABEL org.opencontainers.image.version=
LABEL org.opencontainers.image.revision="Source control revision identifier for the packaged software."
LABEL org.opencontainers.image.licenses=BSD-3-Clause
LABEL org.opencontainers.image.ref.name=
LABEL org.opencontainers.image.title="Docker Perdition with imapproxy image (ubuntu)"
LABEL org.opencontainers.image.base.name=ghcr.io/thefoundation-builder/docker-perdition:alpine

