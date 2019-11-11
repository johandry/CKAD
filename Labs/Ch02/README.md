# Chapter 2: Kubernetes Architecture

##### Check cluster info

```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl describe nodes
kubectl get all
kubectl get all --all-namespaces
```

##### List resources

```bash
kubectl api-resources
```

##### Create pod

Use `run` and `--restart=Never`:

```bash
kubectl run nginx --image=nginx --restart=Never
```

##### Create deployment

Do not use `--restart=Never`

```bash
kubectl run nginx --image=nginx
```

To have multiple replicas use `--replicas=n`, to export the service on a port use `--port=PORT`, to create the service use `--expose`

```bash
kubectl run nginx --image=nginx --replicas=6 --port=80 --expose
```

##### Check nginx

Get the service IP: `kubectl get svc nginx`
If there is no service (no `--expose`), get the pod IP (use `--port=80`)

```bash
kubectl get pods -o wide
```

```bash
kubectl run busybox --image=busybox -it --rm --restart=Never -- wget -O- 10.107.69.177:80
```

##### Multiple containers

1. Create pod manifest:
   
   ```bash
   kubectl run nginx --image=nginx --restart=Never --dry-run=true -o yaml > nginx.yaml
   ```

2. Edit it to add a second container inside `spec.containers[]`, for example:

  ```yaml
    - name: fdlogger
      image: fluent/fluentd
  ```

3. Create the pod:

   ```bash
   kubectl create -f nginx.yaml
   ```

4. Execute a command inside specific container:

   ```bash
   kubectl exec nginx -it -c fdlogger -- /bin/sh
   ```