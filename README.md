# env-v2ray-nginx-tls for docker
## How to use
[![This image on DockerHub](https://img.shields.io/docker/pulls/awei/env-v2ray-nginx-tls.svg)](https://hub.docker.com/r/awei/env-v2ray-nginx-tls/)

[View on Docker Hub](https://hub.docker.com/r/awei/env-v2ray-nginx-tls)

Images are built by GitHub Actions and published to GitHub Container Registry:

```shell
$ docker pull ghcr.io/chenwei791129/env-v2ray-nginx-tls
```

Tags: `latest` (also `master`) and the V2Ray version the image runs, e.g.
`ghcr.io/chenwei791129/env-v2ray-nginx-tls:5.54.2`. The weekly rebuild refreshes the
tags of the current V2Ray version with Alpine's latest package fixes; tags of
older V2Ray versions are kept but no longer rebuilt.

The Docker Hub image `awei/env-v2ray-nginx-tls` is no longer updated.

The image runs [V2Fly](https://github.com/v2fly/v2ray-core) (the maintained
continuation of V2Ray) v5, built from the release pinned in `v2ray/go.mod`,
behind Alpine's nginx package. Dependabot keeps that release, the Alpine base
image and the Go toolchain up to date; every merge to `master` and a weekly
rebuild publish a new image for `linux/amd64` and `linux/arm64`.

> **Upgrading from the v2ray/official based image:**
> - V2Fly only accepts VMess AEAD authentication, so clients must set `alterId`
>   to `0`. To temporarily keep legacy clients working, add
>   `-e V2RAY_VMESS_AEAD_FORCED=false` and set `VMESS_ALTERID` to the clients'
>   value.
> - The fixed fallback VMess ID is gone: without `VMESS_ID` a random ID is
>   generated on every container start, so always set `VMESS_ID`.
> - Arguments passed to the container run as a command instead of the proxy
>   (e.g. `docker run --rm -it ghcr.io/chenwei791129/env-v2ray-nginx-tls sh`).

```shell
$ docker run -d -p <PORT>:<DOCKER-PORT> -e VMESS_ID="<UUID>" -e VMESS_HTTP2_DOMAIN="<DOMAIN>" ghcr.io/chenwei791129/env-v2ray-nginx-tls
```
e.g. need 80 port to get let's encrypt cert
```shell
$ docker run -d -p 80:80 -p 443:443 -e VMESS_ID="877e125d-1ef3-40ef-9329-b7ec62c1072c" -e VMESS_HTTP2_DOMAIN="www.demo.com" ghcr.io/chenwei791129/env-v2ray-nginx-tls
```
e.g. run in arukas.io
```shell
$ docker run -d -p 80:80 -e VMESS_ID="877e125d-1ef3-40ef-9329-b7ec62c1072c" -e ARUKAS_MODE="true" ghcr.io/chenwei791129/env-v2ray-nginx-tls
```
deploy to kubernetes example (Need to match port forwarding 80 port to 30080 port):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: service-v2ray-1
spec:
  selector:
    app: v2ray-1
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080
    - name: https
      protocol: TCP
      port: 443
      targetPort: 443
      nodePort: 30443
  type: NodePort

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: deployment-v2ray-1
  labels:
    app: v2ray-1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: v2ray-1
  template:
    metadata:
      labels:
        app: v2ray-1
    spec:
      containers:
      - name: v2ray-1
        image: ghcr.io/chenwei791129/env-v2ray-nginx-tls:latest
        env:
        - name: VMESS_ID
          value: "877e125d-1ef3-40ef-9329-b7ec62c1072c"
        - name: VMESS_HTTP2_DOMAIN
          value: "www.demo.com"
        - name: DENY_LAN_ACCESS
          value: "true"
        ports:
        - name: https
          containerPort: 443
        - name: http
          containerPort: 80
```
## v2ray client special settings
* `Port` 443 (recommend)
* `Network` ws
* `Host` your.domain
* `Path` /v2ray
* `Transport layer security` tls

### Necessary Environment Variables
* `VMESS_ID` Set a UUID, see [www.uuidgenerator.net](https://www.uuidgenerator.net/) (when unset, a random one is generated and logged on every start)
* `VMESS_HTTP2_DOMAIN` your domain (string, not needed when `ARUKAS_MODE=true`)

### Option Environment Variables
* `VMESS_ALTERID` (integer,default: 0) only used by legacy clients together with `V2RAY_VMESS_AEAD_FORCED=false`
* `DENY_LAN_ACCESS` if set true, v2ray client can't access lan ip (boolean,default: "true")
* `DHPARAM_LENGTH` set Diffie-Hellman parameters (integer,default: 2048)
* `ARUKAS_MODE` if you run image in arukas.io, this option must be true or use CloudFlare Proxied & Flexible mode (boolean,default: "false")
* `URL_PATH` URL path (string,default: "/v2ray", letters, digits and `. _ ~ / -` only)
* `ACME_SERVER` acme.sh CA used to issue the certificate (string,default: "letsencrypt")

### Option
* Recommended with cloudflare CDN use

## Related Projects
- [v2fly/v2ray-core](https://github.com/v2fly/v2ray-core)
- [acmesh-official/acme.sh](https://github.com/acmesh-official/acme.sh)
- [nginx/nginx](https://github.com/nginx/nginx)

## License
The repository is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
