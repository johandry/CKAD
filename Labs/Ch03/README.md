# Chapter 3: Build

#### Create a deployment and scale it

```bash
kubectl create deployment simpleapp --image=johandry/simpleapp
kubectl scale deployment simpleapp --replicas=6
```

#### Get deployment manifest

```bash
kubectl get deployment simpleapp -o yaml
```

#### Readiness Probe

Include in `deployment.spec.template.spec.containers[n].readinessProbe`:

```yaml
  readinessProbe:
    periodSeconds: 5
    exec:
      command:
      - cat
      - /tmp/healthy
```

```yaml
  readinessProbe:
    tcpSocket:
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 10
```

#### Liveness Probe

Include in `deployment.spec.template.spec.containers[n].livenessProbe`:

```yaml
  livenessProbe:
    tcpSocket:
      port: 8080
    initialDelaySeconds: 15
    periodSeconds: 20
```
