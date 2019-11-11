# Chapter 2: Kubernetes Architecture

- **Check cluster info**
  `kubectl cluster-info`
  `kubectl get nodes -o wide`
  `kubectl describe nodes`
  `kubectl get all`
  `kubectl get all --all-namespaces`

- **List resources**
  `kubectl api-resources`

- **Create pod**:
  Use `run` and `--restart=Never`:
  `kubectl run nginx --image=nginx --restart=Never`

- **Create deployment**
  Do not use `--restart=Never`
  `kubectl run nginx --image=nginx`
  With replicas use `--replicas=n`, with port use `--port=PORT`, with service use `--expose`
  `kubectl run nginx --image=nginx --replicas=6 --port=80 --expose`

- **Check nginx**
  Get the service IP: `kubectl get svc nginx`
  If there is no service (no `--expose`), get the pod IP (use `--port=80`): `kubectl get pods -o wide`

  `kubectl run busybox --image=busybox -it --rm --restart=Never -- wget -O- 10.107.69.177:80`

- **Multiple containers**
  Create pod manifest:
  `kubectl run nginx --image=nginx --restart=Never --dry-run=true -o yaml > nginx.yaml`
  
  Edit it to add a second container inside `spec.containers[]`, for example:

  ```yaml
  - name: fdlogger
    image: fluent/fluentd
  ```

  Create the pod:
  `kubectl create -f nginx.yaml`

  Execute a command inside specific container:
  `kubectl exec nginx -it -c fdlogger -- /bin/sh`