# env-v2ray-nginx-h2 for docker
## How to use
[![This image on DockerHub](https://img.shields.io/docker/pulls/awei/env-v2ray-nginx-h2.svg)](https://hub.docker.com/r/awei/env-v2ray-nginx-h2/)

[View on Docker Hub](https://hub.docker.com/r/awei/env-v2ray-nginx-h2)

```shell
$ docker run -d -p <PORT>:<DOCKER-PORT> -e VMESS_ID="<UUID>" -e VMESS_HTTP2_DOMAIN="<DOMAIN>" awei/env-v2ray-nginx-h2
```
e.g. (VMess+nginx+tls+h2) need 80 port to get let's encrypt cert
```shell
$ docker run -d -p 80:80 -p 443:443 -e VMESS_ID="877e125d-1ef3-40ef-9329-b7ec62c1072c" -e VMESS_HTTP2_DOMAIN="www.demo.com" awei/env-v2ray-nginx-h2
```
deploy to kubernetes example:
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
        image: awei/env-v2ray-nginx-h2:latest
        env:
        - name: VMESS_ID
          value: "39de9465-16a5-499a-93ef-d05e946214ce"
        - name: DENY_LAN_ACCESS
          value: "true"
        ports:
        - name: https
          containerPort: 443
        - name: http
          containerPort: 80
```
### Necessary Environment Variables
* `[VMess] VMESS_ID` Set a UUID, see [www.uuidgenerator.net](https://www.uuidgenerator.net/)

### Option Environment Variables
* `[VMess] VMESS_ALTERID` (integer,default: 64)
* `[VMess] VMESS_HTTP2_DOMAIN` your domain (string)
* `DENY_LAN_ACCESS` if set true, v2ray client can't access lan ip (boolean,default: "true")

## Related Projects
- [v2ray/official](https://hub.docker.com/r/v2ray/official)

## License
The repository is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
