#!/bin/sh
# Configure nginx (TLS + WebSocket reverse proxy) and v2ray from environment
# variables, issue a Let's Encrypt certificate when needed, then run v2ray.
set -eu

# Run a given command instead (e.g. `docker run --rm -it <image> sh`).
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

CONFIG=/etc/v2ray/config.json
TEMPLATES=/usr/local/share/v2ray-nginx
SITES=/etc/nginx/http.d
CERT_DIR=/etc/nginx/cert

# Destinations blocked when DENY_LAN_ACCESS=true. Listed explicitly instead of
# "geoip:private" so the image does not need to ship and update geoip.dat.
PRIVATE_IPS='["0.0.0.0/8","10.0.0.0/8","100.64.0.0/10","127.0.0.0/8",
  "169.254.0.0/16","172.16.0.0/12","192.0.0.0/24","192.0.2.0/24",
  "192.88.99.0/24","192.168.0.0/16","198.18.0.0/15","198.51.100.0/24",
  "203.0.113.0/24","224.0.0.0/4","240.0.0.0/4","255.255.255.255/32",
  "::/128","::1/128","fc00::/7","fe80::/10","ff00::/8"]'

die() {
  echo "[Error] $*" >&2
  exit 1
}

url_path="${URL_PATH:-/v2ray}"
# The path is substituted into nginx configs, so only allow plain URL characters.
case "${url_path}" in
  [!/]* | *[!A-Za-z0-9._~/-]*)
    die "URL_PATH must start with '/' and only contain letters, digits and . _ ~ / -" ;;
esac
# Like the old setup.sh, any value other than "false" selects Arukas mode.
if [ "${ARUKAS_MODE:-false}" = false ]; then
  arukas=false
else
  arukas=true
fi
domain="${VMESS_HTTP2_DOMAIN:-}"
if [ "${arukas}" != true ] && [ -z "${domain}" ]; then
  die 'VMESS_HTTP2_DOMAIN is required when ARUKAS_MODE=false.'
fi

# Copy an nginx site template, replacing the default /v2ray location.
render_site() {
  sed "s#/v2ray#${url_path}#g" "${TEMPLATES}/$1" > "${SITES}/$2"
}

# Start nginx with the plain HTTP site only; the TLS site is added once a
# certificate exists (the HTTP site serves the ACME challenge).
rm -f "${SITES}/v2ray-nginx-h2.conf"
if [ "${arukas}" = true ]; then
  echo '[Info] Run in arukas.io, use default-arukas.conf.'
  render_site default-arukas.conf default.conf
else
  render_site default.conf default.conf
fi
nginx

echo '[Info] Protocol is VMess.'
if [ -z "${VMESS_ID:-}" ]; then
  VMESS_ID="$(v2ray uuid)"
  echo "[Warn] VMESS_ID is not set, generated a random one: ${VMESS_ID}"
fi
jq --arg id "${VMESS_ID}" --argjson alterId "${VMESS_ALTERID:-0}" \
  --arg path "${url_path}" \
  '.inbounds = [{port: 10086, listen: "127.0.0.1", protocol: "vmess",
     settings: {clients: [{id: $id, alterId: $alterId}]},
     streamSettings: {network: "ws", wsSettings: {path: $path}}}]' \
  /etc/v2ray/config.json-default > "${CONFIG}"

if [ "${DENY_LAN_ACCESS:-true}" = true ]; then
  echo '[Info] Apply DENY LAN ACCESS.'
  jq --argjson ips "${PRIVATE_IPS}" \
    '.outbounds += [{protocol: "blackhole", settings: {}, tag: "blocked"}]
     | .routing = {rules: [{type: "field", ip: $ips, outboundTag: "blocked"}]}' \
    "${CONFIG}" > "${CONFIG}.tmp"
  mv "${CONFIG}.tmp" "${CONFIG}"
fi

if [ "${arukas}" != true ]; then
  if [ ! -f "${CERT_DIR}/dhparam.pem" ]; then
    echo '[Info] Generating Diffie-Hellman parameters (Logjam mitigation).'
    openssl dhparam -out "${CERT_DIR}/dhparam.pem" "${DHPARAM_LENGTH:-2048}"
  fi
  if [ ! -f "${CERT_DIR}/cert.pem" ] || [ ! -f "${CERT_DIR}/key.pem" ]; then
    acme_server="${ACME_SERVER:-letsencrypt}"
    echo "[Info] Issuing a certificate for ${domain} from ${acme_server}."
    # Exit code 2 means a still-valid certificate was already issued.
    acme.sh --issue --server "${acme_server}" -d "${domain}" -w /www \
      --keylength ec-384 || [ $? -eq 2 ]
    acme.sh --install-cert --ecc -d "${domain}" \
      --key-file "${CERT_DIR}/key.pem" --fullchain-file "${CERT_DIR}/cert.pem" \
      --reloadcmd 'nginx -s reload'
  fi
  render_site v2ray-nginx-h2.conf v2ray-nginx-h2.conf
  nginx -s reload
fi

echo '[Debug] Dump config.json:'
jq -c . "${CONFIG}"
if [ "${arukas}" != true ]; then
  echo "[Success] Your vmess domain is: ${domain}"
fi
echo "[Success] Your vmess ID is: ${VMESS_ID}"
echo "[Success] Your vmess path is: ${url_path}"

exec v2ray run -c "${CONFIG}"
