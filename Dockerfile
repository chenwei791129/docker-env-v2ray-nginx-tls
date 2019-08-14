FROM v2ray/official

ENV VMESS_ID= \
    VMESS_ALTERID=64 \
    VMESS_HTTP2_DOMAIN= \
    DENY_LAN_ACCESS=true

COPY config.json /etc/v2ray/config.json-default
COPY setup.sh /tmp/
COPY default.conf /etc/nginx/conf.d/default.conf
COPY v2ray-nginx-h2.conf /tmp/

RUN apk add --update jq curl openssl socat nginx && \
    curl https://get.acme.sh | sh && \
#    adduser -D -g 'nginx' nginx && \
    mkdir /www && \
    mkdir /etc/nginx/cert && \
    mkdir /run/nginx && \
    chown -R nginx:nginx /www

CMD /bin/sh /tmp/setup.sh && \
    v2ray -config=/etc/v2ray/config.json

EXPOSE 80 443
