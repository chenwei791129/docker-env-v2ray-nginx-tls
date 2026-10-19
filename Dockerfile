# syntax=docker/dockerfile:1

# Build v2ray from the v2fly/v2ray-core release pinned in v2ray/go.mod, which
# Dependabot keeps up to date. The prebuilt v2fly/v2fly-core image is not used
# because it is published by hand and lags the GitHub releases.
FROM --platform=$BUILDPLATFORM golang:1.27.2-alpine AS v2ray
ARG TARGETOS
ARG TARGETARCH
WORKDIR /src
COPY v2ray/go.mod v2ray/go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w -buildid=" -o /out/v2ray \
      github.com/v2fly/v2ray-core/v5/main

# nginx and acme.sh come from Alpine's packages: they are updated with the base
# image and picked up by the weekly scheduled rebuild.
FROM alpine:3.24.2

ENV VMESS_ID= \
    VMESS_ALTERID=0 \
    VMESS_HTTP2_DOMAIN= \
    DENY_LAN_ACCESS=true \
    DHPARAM_LENGTH=2048 \
    ARUKAS_MODE=false \
    URL_PATH="/v2ray"

# Changes on every CI build (see docker-image.yml) so this layer is never
# reused from the build cache and always gets Alpine's latest package fixes.
ARG APK_REFRESH
# openssl is listed explicitly: acme.sh only depends on "cmd:openssl", which
# can resolve to aws-lc-tools, and acme.sh cannot create keys with that.
RUN apk upgrade --no-cache \
    && apk add --no-cache acme.sh jq nginx openssl \
    && mkdir -p /etc/nginx/cert /run/nginx /www

COPY --from=v2ray /out/v2ray /usr/bin/v2ray
COPY config.json /etc/v2ray/config.json-default
COPY default.conf default-arukas.conf v2ray-nginx-h2.conf /usr/local/share/v2ray-nginx/
COPY --chown=nginx:nginx index.html /www/
COPY --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
