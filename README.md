# env-v2ray-nginx-tls for docker
## How to use
[![This image on DockerHub](https://img.shields.io/docker/pulls/awei/env-v2ray-nginx-tls.svg)](https://hub.docker.com/r/awei/env-v2ray-nginx-tls/)

[View on Docker Hub](https://hub.docker.com/r/awei/env-v2ray-nginx-tls)

```shell
$ docker run -d -p <PORT>:<DOCKER-PORT> -e VMESS_ID="<UUID>" -e VMESS_HTTP2_DOMAIN="<DOMAIN>" awei/env-v2ray-nginx-tls
```
e.g. need 80 port to get let's encrypt cert
```shell
$ docker run -d -p 80:80 -p 443:443 -e VMESS_ID="877e125d-1ef3-40ef-9329-b7ec62c1072c" -e VMESS_HTTP2_DOMAIN="www.demo.com" awei/env-v2ray-nginx-tls
```
e.g. run in arukas.io
```shell
$ docker run -d -p 80:80 -e VMESS_ID="877e125d-1ef3-40ef-9329-b7ec62c1072c" -e ARUKAS_MODE="true" awei/env-v2ray-nginx-tls
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
        image: awei/env-v2ray-nginx-tls:latest
        env:
        - name: VMESS_ID
          value: "877e125d-1ef3-40ef-9329-b7ec62c1072c"
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
* `Host` <DOMAIN>
* `Path` /v2ray
* `Transport layer security` tls

### Necessary Environment Variables
* `VMESS_ID` Set a UUID, see [www.uuidgenerator.net](https://www.uuidgenerator.net/)
* `VMESS_HTTP2_DOMAIN` your domain (string)

### Option Environment Variables
* `VMESS_ALTERID` (integer,default: 64)
* `DENY_LAN_ACCESS` if set true, v2ray client can't access lan ip (boolean,default: "true")
* `DHPARAM_LENGTH` set Diffie-Hellman parameters (integer,default: 2048)
* `ARUKAS_MODE` if you run image in arukas.io, this option must be true (boolean,default: "false")

## Related Projects
- [v2ray/official](https://hub.docker.com/r/v2ray/official)
- [Neilpang/acme.sh](https://github.com/Neilpang/acme.sh)
- [nginx/nginx](https://github.com/nginx/nginx)

## License
The repository is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
