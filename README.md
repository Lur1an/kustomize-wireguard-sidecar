# kustomize-wireguard-sidecar
This is a kustomize component to add `linuxserver/wireguard` as a sidecar to your kubernetes deployments/statefulsets.

## Usage
Look at the `examples/hello-world` kustomization deployment:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: hello-world
resources:
- namespace.yaml
- deployment.yaml
- service.yaml
- wireguard-secret.yaml

components:
- https://github.com/lur1an/kustomize-wireguard-sidecar
```
To make everything work you need to create a `wireguard-secret` secret in the namespace with a `wg0.conf`string value, this secret is mounted as a read only volume in a init-container and copied to a read/write volume that the wireguard container then uses to set up your connection:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wireguard-secret
type: Opaque
stringData:
  wg0.conf: |
    [Interface]
    PrivateKey = <YOUR_PRIVATE_KEY>
    Address = <YOUR_ADDRESS>
    DNS = <YOUR_DNS>

    [Peer]
    PublicKey = <YOUR_PUBLIC_KEY>
    AllowedIPs = 0.0.0.0/0
    Endpoint = <THE_ENDPOINT>
```
I've redacted the wireguard config itself, how wireguard spefically works is out of scope of the repository.

As a last step you need to mark the `Deployment` or `StatefulSet` with the label `wireguard-sidecar=enable` and the sidecar will be added to it.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world
  namespace: hello-world
  labels:
    wireguard-sidecar: enable
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: testcontainers/helloworld
        imagePullPolicy: Always
      restartPolicy: Always
```

## StatefulSet differences
When using a `StatefulSet` the secret needs to contain a wireguard manifest for every pod in the set.
For example when doing a 3 replica stateful set for `hello-world`:
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: hello-world
  namespace: hello-world
  labels:
    wireguard-sidecar: enable
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: testcontainers/helloworld
        imagePullPolicy: Always
        volumeMounts:
        - mountPath: /deeznuts
          name: deeznuts
      restartPolicy: Always

      volumes:
      - emptyDir: {}
        name: deeznuts
```
The secret structure needs to be:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wireguard-secret
type: Opaque
stringData:
  wg0-hello-world-0.conf: |
    "WIREGUARD_CONFIG FOR POD HELLO-WORLD-0"

  wg0-hello-world-1.conf: |
    "WIREGUARD_CONFIG FOR POD HELLO-WORLD-1"
```
This allows to configure different wireguard configs and so IP's for each pod in the stateful set.

## Why labels and not annotations for patch selection?
I'm building this especially for use with the `docker-selenium` chart to add wireguard sidecar containers to browser nodes, the chart doesn't allow adding annotations to the `Deployment` generated by the chart itself, however the chart does add labels to it. (Annotations are added to the template for the `Pod` in the `Deployment`, however to target the deployment itself we need to add something to it so we use the labels)

## How to allow cluster communication while wireguard is up
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wireguard-secret
type: Opaque
stringData:
  wg0.conf: |
    [Interface]
    PrivateKey = <YOUR_PRIVATE_KEY>
    Address = <ADDRESS>
    PostUp = ip route add 10.0.0.0/16 via 10.244.0.1 dev eth0
    PostUp = ip route add 10.96.0.0/16 via 10.244.0.1 dev eth0
    PostDown = ip route del 10.0.0.0/16 via 10.244.0.1 dev eth0 
    PostDown = ip route del 10.96.0.0/16 via 10.244.0.1 dev eth0 

    [Peer]
    # DE#241
    PublicKey = <YOUR_PUBLIC_KEY>
    AllowedIPs = 0.0.0.0/0
    Endpoint = 217.138.216.98:51820
```
