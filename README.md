# Kubernetes for Developers

This is my personal quick guide to study for the CKAD. It contain my notes from the training [Kubernetes for Developers](https://training.linuxfoundation.org/training/kubernetes-for-developers/) from CNFN/Linux Foundation, other pages or guides to study for CKAD and the book [Kubernetes Cookbook](https://www.amazon.com/Kubernetes-Cookbook-Building-Native-Applications/dp/1491979682).

## Chapters

1. Chapter 1: Introduction
2. Chapter 2: [Kubernetes Architecture](./Labs/Ch02)
3. Chapter 3: [Build](./Labs/Ch03)
4. Chapter 4: [Design](./Labs/Ch04)
5. Chapter 5: [Deployment Configuration](./Labs/Ch05)
6. Chapter 6: [Security](./Labs/Ch06)
7. Chapter 7: Exposing Applications
8. Chapter 8: Troubleshooting

For each chapter there is a README with the notes from the training and other pages, the PDF files for the Labs for each chapter, a `solution.sh` script with the solutions to the Labs from the training and, for some chapters, some aditional files used for the Labs.

For the test use Google Chrome and install the [PSI Chrome Extension](https://chrome.google.com/webstore/detail/innovative-exams-screensh/dkbjhjljfaagngbdhomnlcheiiangfle) 

## General Tips

#### API Resources

```bash
kubectl api-resources
```

#### kubectl explain

```bash
kubectl explain deployment
kubectl explain deployment --recursive
kubectl explain deployment.spec.strategy
```

#### Cluster information

```bash
kubectl cluster-info
kubectl get nodes
kubectl get all --all-namespaces
```

#### Generators

Append `-o yaml --export` to getting an existing resource:

```bash
kubectl get po nginx -o yaml --export
```

Or append to `kubectl run NAME --image=IMAGE` the parameters `--dry-run -o yaml` and one of the followings to create a Pod, Deployment, Deployment + Replica Set + Service, Job or Cron Job:

#### Pod

Append `--restart=Never`

```bash
kubectl run nginx --image=nginx --dry-run -o yaml --restart=Never
```

#### Deployment

Append `--restart=Always` or don't use it, as it's the default value.

```bash
kubectl run nginx --image=nginx --dry-run -o yaml
```

#### Deployment + Replica Set + Service

To have a Replica Set append `--replicas=N`, to have a Service append `--port=PORT --expose`.

```bash
kubectl run nginx --image=nginx --dry-run -o yaml --restart=Always --port=80 --expose --replicas=5
```

#### Job

Append `--restart=OnFailure --command -- COMMAND`.

```bash
kubectl run sleepy --image=busybox --dry-run -o yaml --restart=OnFailure --command -- /bin/sleep 3
```

#### Cron Job

Append `--restart=OnFailure --schedule="SCHEDULE" --command -- COMMAND`.

```bash
kubectl run sleepy --image=busybox --dry-run -o yaml --restart=OnFailure --schedule="*/2 * * * *" --command -- /bin/sleep 3
```

#### kubectl cheatsheet

Go to kubernetes.io -> Reference -> kubectl CLI -> [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

#### kubectl commands reference

Go to kubernetes.io -> Reference -> kubectl CLI -> kubectl Commands -> [kubectl Command Reference](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands)

#### kubectl run to generate resources

Go to kubernetes.io -> Reference -> kubectl CLI -> kubectl Usage Conventions -> Scroll down to Best Practices -> [Generators](https://kubernetes.io/docs/reference/kubectl/conventions/#generators)

#### Shell into a container

Go to kubernetes.io -> Tasks -> Monitoring, Logging, and Debugging -> [Get a Shell to a Running Container](https://kubernetes.io/docs/tasks/debug-application-cluster/get-shell-running-container/)

```bash
kubectl exec -it shell-demo -- /bin/bash
kubectl exec shell-demo env
kubectl run busybox --image=busybox -it --rm -- env
```

#### Using port forwarding

Go to kubernetes.io -> Tasks -> Access Applications in a Cluster -> [Use Port Forwarding to Access Applications in a Cluster](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)

#### Create pod

```bash
kubectl create namespace myns
kubectl run nginx --image=nginx --restart=Never -n myns
```

To allow traffic in a port, append: `--port=80`

```bash
kubectl create namespace myns
kubectl run nginx --image=nginx --restart=Never --port=80 -n myns
```

To check the pod, get the pod IP and use a temporal pod to access the pod service:

```bash
kubectl get pod -o wide # get the IP
kubectl run busybox --image=busybox -it --rm --restart=Never -- wget -O- $IP:80
```

#### Change pod image

```bash
kubectl set image pod/nginx nginx=nginx:1.8
kubectl describe po nginx

kubectl get pods -w
# Or
watch -n 5 kubectl get pods
```

#### Get pod information

```bash
kubectl describe pod nginx
kubectl logs nginx

# From previous instance, when the pod crashed
kubectl logs nginx -p
```

## Linux Foundation Resources

List of resources from Linux Foundation ([current version](https://training.linuxfoundation.org/cncf-certification-candidate-resources/))

[CKAD Candidate Handbook](https://training.linuxfoundation.org/go/cka-ckad-candidate-handbook) | [here](./CKA-CKAD-Candidate-Handbook-v1.6.pdf)

[CKAD Exam Tips](http://training.linuxfoundation.org/go//Important-Tips-CKA-CKAD) | [here](./Important-Tips-CKA-CKAD-Master-11.20.19.pdf)

[CKAD FAQ](http://training.linuxfoundation.org/go/cka-ckad-faq) | [here](./CKA-CKAD-FAQ-11.22.19.pdf)

## Sources

- **Kubernetes for Developers Labs**: https://lms.quickstart.com/custom/862120/LFD259-labs_V2019-08-19.pdf
- **Kubernetes for Developers Solution**: https://training.linuxfoundation.org/cm/LFD259/LFD259_V2019-08-19_SOLUTIONS.tar.bz2
- **dgkanatsios/CKAD-exercises**: https://github.com/dgkanatsios/CKAD-exercises

