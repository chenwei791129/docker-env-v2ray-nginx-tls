#Experiment: Join nginx base image let dockerhub detection nginx version update
FROM nginx:alpine

FROM v2ray/official

ENV VMESS_ID= \
    VMESS_ALTERID=64 \
    VMESS_HTTP2_DOMAIN= \
    DENY_LAN_ACCESS=true \
    DHPARAM_LENGTH=2048 \
    ARUKAS_MODE=false \
    URL_PATH="/v2ray"

COPY config.json /etc/v2ray/config.json-default
COPY setup.sh v2ray-nginx-h2.conf default.conf default-arukas.conf /tmp/
COPY index.html /www/

    # add mainline nginx package source,see http://nginx.org/en/linux_packages.html#Alpine
RUN apk add --update curl nss openssl && \
    curl -o /etc/apk/keys/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub && \
    printf "%s%s%s\n" "http://nginx.org/packages/mainline/alpine/v" `egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release` "/main" >> /etc/apk/repositories && \
    # install nginx and acme.sh
    apk add --update jq socat nginx && \
    curl https://get.acme.sh | sh && \
    mkdir -p /etc/nginx/cert && \
    mkdir -p /run/nginx && \
    chown -R nginx:nginx /www

CMD /bin/sh /tmp/setup.sh && \
    v2ray -config=/etc/v2ray/config.json

EXPOSE 80 443
