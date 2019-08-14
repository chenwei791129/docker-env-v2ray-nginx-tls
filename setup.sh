#!/bin/sh

cp -f /tmp/default.conf /etc/nginx/conf.d/default.conf
nginx

cp -f /etc/v2ray/config.json-default /etc/v2ray/config.json
cp -f /tmp/v2ray-nginx-h2.conf /etc/nginx/conf.d/v2ray-nginx-h2.conf

# Setup vmess
echo '[Info] Protocal is VMess.'
echo $(cat /etc/v2ray/config.json | jq '.inbounds += [{"port":10086,"protocol":"vmess","settings":{"clients":[{"id":"60ca58e9-003e-4c01-98de-c2223ae49153","alterId":64}]}}]') > /etc/v2ray/config.json

if [ -n "${VMESS_ID}" ]; then
  echo '[Info] Setup id.'
  echo $(cat /etc/v2ray/config.json | jq '.inbounds[0].settings.clients[0].id = "'${VMESS_ID}'"') > /etc/v2ray/config.json
fi

if [ -n "${VMESS_ALTERID}" ]; then
  echo '[Info] Setup alterId.'
  echo $(cat /etc/v2ray/config.json | jq '.inbounds[0].settings.clients[0].alterId = '${VMESS_ALTERID}'') > /etc/v2ray/config.json
fi

echo $(cat /etc/v2ray/config.json | jq '.inbounds[0] += {"streamSettings":{"network":"ws","wsSettings":{"path":"/v2ray"}}}') > /etc/v2ray/config.json

if [ ${DENY_LAN_ACCESS} == true ]; then
  echo '[Info] Apply DENY LAN ACCESS.'
  # add blackhole outbound for private ip route rule
  echo $(cat /etc/v2ray/config.json | jq '.outbounds += [{"protocol":"blackhole","settings":{},"tag":"blocked"}]') > /etc/v2ray/config.json
  # add private ip route rule
  echo $(cat /etc/v2ray/config.json | jq '. += {"routing":{"rules":[{"type":"field","ip":["geoip:private"],"outboundTag":"blocked"}]}}') > /etc/v2ray/config.json
fi

if [ ! -f /etc/nginx/cert/cert.pem ] && [ ! -f /etc/nginx/cert/key.pem ] && [ ! -f /etc/nginx/cert/dhparam.pem ]; then
  echo '[Info] Start set Weak Diffie-Hellman and the Logjam Attack:'
  openssl dhparam -out /etc/nginx/cert/dhparam.pem 4096
  echo '[Info] Start get cert:'
  /root/.acme.sh/acme.sh --issue -d "${VMESS_HTTP2_DOMAIN}" -w /www --keylength ec-384
  echo '[Info] Start install cert:'
  /root/.acme.sh/acme.sh --install-cert -d "${VMESS_HTTP2_DOMAIN}" --key-file /etc/nginx/cert/key.pem --fullchain-file /etc/nginx/cert/cert.pem --capath /etc/nginx/cert/ca.pem --reloadcmd "nginx -s reload" --ecc
fi

echo '[Debug] Dump config.json:'
echo $(cat /etc/v2ray/config.json)
echo "[Success] Your vmess domain is: ${VMESS_HTTP2_DOMAIN}"
echo "[Success] Your vmess ID is: $(cat /etc/v2ray/config.json | jq -r '.inbounds[0].settings.clients[0].id')"
echo "[Success] Your vmess Alter ID is: $(cat /etc/v2ray/config.json | jq -r '.inbounds[0].settings.clients[0].alterId')"
echo "[Success] Your vmess path is: /v2ray"
