# Kubernetes for Developers

## Chapters

1. Chapter 1: Introduction
2. Chapter 2: [Kubernetes Architecture](./Las/Ch02)
3. Chapter 3: [Build](./Las/Ch03)
4. Chapter 4: [Design](./Las/Ch04)

## Tips

##### API Resources

```bash
kubectl api-resources
```

##### kubectl explain

```bash
kubectl explain deployment
kubectl explain deployment --recursive
kubectl explain deployment.spec.strategy
```

##### Cluster information

```bash
kubectl cluster-info
kubectl get nodes
kubectl get all --all-namespaces
```

##### Generate manifest

Append to `run` the parameter `--dry-run=true -o yaml`:

```bash
kubectl run nginx --image=nginx --restart=Never --dry-run=true -o yaml
```

Append `-o yaml --export` to an existing resource

```bash
kubectl get po nginx -o yaml --export
```

##### kubectl cheatsheet

Go to kubernetes.io -> Reference -> kubectl CLI -> [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

##### kubectl commands reference

Go to kubernetes.io -> Reference -> kubectl CLI -> kubectl Commands -> [kubectl Command Reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)

##### kubectl run to generate resources

Go to kubernetes.io -> Reference -> kubectl CLI -> kubectl Usage Conventions -> Scroll down to Best Practices -> [Generators](https://kubernetes.io/docs/reference/kubectl/conventions/#generators)

##### Shell into a container

Go to kubernetes.io -> Tasks -> Monitoring, Logging, and Debugging -> [Get a Shell to a Running Container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/)

```bash
kubectl exec -it shell-demo -- /bin/bash
kubectl exec shell-demo env
kubectl run busybox --image=busybox -it --rm -- env
```

##### **Using port forwarding**

Go to kubernetes.io -> Tasks -> Access Applications in a Cluster -> [Use Port Forwarding to Access Applications in a Cluster](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)

##### Create pod

```bash
kubectl create namespace myns
kubectl run nginx --image=nginx --restart=Never -n myns
```

To generate the manifest append: `--dry-run=true -o yaml`, to allow traffic in a port, append: `--port=80`

```bash
kubectl create namespace myns
kubectl run nginx --image=nginx --restart=Never --port=80 --dry-run=true -o yaml -n myns
```

To check the pod, get the pod IP and use a temporal pod to access the pod service:

```bash
kubectl get pod -o wide # get the IP
kubectl run busybox --image=busybox -it --rm --restart=Never -- wget -O- $IP:80
```

##### Change pod image

```bash
kubectl set image pod/nginx nginx=nginx:1.8
kubectl describe po nginx

kubectl get pods -w
# Or
watch -5 kubectl get pods
```

##### Get pod information

```bash
kubectl describe pod nginx
kubectl logs nginx

# From previous instance, when the pod crashed
kubectl logs nginx -p
```

## Sources

- **Kubernetes for Developers Labs**: https://lms.quickstart.com/custom/862120/LFD259-labs_V2019-08-19.pdf
- **Kubernetes for Developers Solution**: https://training.linuxfoundation.org/cm/LFD259/LFD259_V2019-08-19_SOLUTIONS.tar.bz2
