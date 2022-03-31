FROM alpine
RUN apk --no-cache upgrade && apk --no-cache add perdition socat curl iproute2
