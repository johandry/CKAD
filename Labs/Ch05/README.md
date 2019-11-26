# Chapter 5: Deployment Configuration

#### Documentation

- kubernetes.io -> Tasks -> Configure Pods and Containers -> [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
- kubernetes.io -> Concepts -> Configuration -> [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- kubernetes.io -> Tasks -> Inject Data Into Applications -> [Distribute Credentials Securely Using Secrets](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/)
- kubernetes.io -> Tasks -> Configure Pods and Containers -> [Configure a Pod to Use a Volume for Storage](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/)
- kubernetes.io -> Tasks -> Configure Pods and Containers -> [Configure a Pod to Use a PersistentVolume for Storage](https://kubernetes.io/docs/tasks/configure-pod-container/configure-persistent-volume-storage/)
- kubernetes.io -> Concepts -> Workloads -> Controllers -> [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

#### ConfigMaps

#### Create ConfigMap from values, files and directories

```bash
echo -e "key1=value1\nkey2=value2" > /path/to/file

kubectl create configmap config \
  --from-literal=akey=avalue \
  --from-file=/path/to/file \
  --from-file=/path/to/dir/
```

#### View ConfigMap

```bash
kubectl get configmap config -o yaml
# Or
kubectl describe configmap config
```

#### Use the ConfigMap as environment variable

```bash
kubectl run nginx --image=nginx --restart=Never --dry-run -o yaml > pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
    resources: {}
    env:
    - name: config        # env var name
      valueFrom:
        configMapKeyRef:
          name: config     # configmap name
          key: akey        # key name in the cm. If ignored, will get all
  dnsPolicy: ClusterFirst
  restartPolicy: Never
status: {}
```

```bash
kubectl create -f pod.yaml
kubectl exec -it nginx -- env
```

#### Use the ConfigMap as volume

```bash
vi pod.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
    resources: {}
    env:
    - name: config        # env var name
      valueFrom:
        configMapKeyRef:
          name: config    # configmap name
          key: akey       # key name in the cm. If ignored, will get all
    volumeMounts:
    - name: my-config-vol  # reference to name of the volume, see below
      mountPath: /etc/config  # path inside the container
  volume:
  - name: my-config-vol    # name of the volume
    configMap:
      name: config        # name of the configMap
  dnsPolicy: ClusterFirst
  restartPolicy: Never
status: {}
```

```bash
kubectl exec -it nginx -- /bin/sh -c 'ls -l /etc/config && cat /etc/config/key1'
```

#### Secrets

#### Create Secret with manifest

Create the base64-encoded output for the data

```bash
echo -n "superpassword" | base64
```

Include it in the `Secret.data` object. Create it from scratch using the documentation.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: demo-secret
data:
  password: c3VwZXJwYXNzd29yZA==
```

#### Create Secret from literal and file

```bash
echo -n "admin" > username

kubectl create secret generic demo-secret-1 \
  --from-literal=password='c3VwZXJwYXNzd29yZA==' \
  --from-file=username

kubectl get secret demo-secret-1 \
  -o jsonpath='{.data.username}{"\n"}' | base64 -d
```

#### Use secrets in a container with volume

Create the Pod or Deployment

```bash
kubectl run nginx --image=nginx --restart=Never -o yaml --dry-run > pod.yaml
```

Add the volume to `spec.volumes` and mount it in the container with `spec.containers[n].volumeMounts`

```yaml
apiVersion: v1
kind: Pod
...
spec:
  volumes:
  - name: demo-secret-volume
    secret:
      secretName: demo-secret-1
  containers:
  - name: nginx
    volumeMounts:
    - name: demo-secret-vm
      mountPath: /etc/secret
    ...
```

Check

```bash
kubectl exec nginx -- /bin/bash -c \
  'ls -l /etc/secret && cat /etc/secret/username && cat /etc/secret/password'
```

It prints the files `username` and `password`, then `admin` and `c3VwZXJwYXNzd29yZA==`.

#### Use secrets in a container with environment variables

Add in the Pod into `spec.containers[n].env`

```yaml
apiVersion: v1
kind: Pod
...
spec:
  containers:
  - name: test-container
    env:
    - name: USERNAME
      valueFrom:
        secretKeyRef:
          name: demo-secret-1
          key: username
    - name: PASSWORD
      valueFrom:
        secretKeyRef:
          name: demo-secret-1
          key: password
    ...
```

Check

```bash
kubectl exec nginx -- /bin/bash -c 'echo $USERNAME:$PASSWORD'
```

#### Volumes

1. Create the Presistent Volume
2. Create the Persistent Volume Claim
3. Add the Volume to the Pod and to the Container

#### Create the Presistent Volume

It's created from scratch, get help from the kubernetes.io documentation

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: demo-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessMode:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
```

If you are in Kubernetes on Docker Desktop, make sure the `path` is in the File Sharing list.

#### Create the Persistent Volume Claim

It's created from scratch, get help from the kubernetes.io documentation

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: demo-pv-claim
spec:
  storageClassName: manual    # use the same class name as the PV
  accessModes:
    - ReadWriteOnce            # use one of the mode used by the PV
  resources:
    request:
      storage: 3Gi            # make sure is =< than the PV capacity
```

When created, make sure the status is `Bound`.

#### Add the Volume to the Pod and to the Container

Generate the code for the Pod or Deployment:

```bash
kubectl run nginx --image=nginx --restart=Never -o yaml --dry-run > pod.yaml
```

Add the volume to the Pod in `Pod.spec.volumes`

```yaml
apiVersion: v1
kind: Pod
...
spec:
  volumes:
    - name: demo-pv-storage
      persistentVolumeClaim:
        claimName: demo-pv-claim
  containers:
  ...
```

Add the volume to the Container in `Pod.spec.containers[n].volumeMounts`

```yaml
apiVersion: v1
kind: Pod
...
spec:
  containers:
    - name: nginx
      volumeMounts:
        - mountPath: "/var/log/nginx"
          name: demo-pv-storage   # same name as in volumes section
      ...
```

To check the content of the volume inside the container use:

```bash
kubectl exec nginx -it -- ls /var/log/nginx
```

In your local system:

```bash
ls /mnt/data
```

They should have the same data.

#### Rollbacks

Use allways version tags in the images, try to avoid `:latest` tag.

To update the pod or deployment use `kubectl set` or `kubectl edit`.

```bash
export KUBE_EDITOR=vim
kubectl edit deployment demo
```

Or,

```bash
kubectl set image deployment demo simpleapp=simpleapp:v2
```

`kubectl set image TYPE NAME CONTAINER1=IMAGE1 CONTAINER2=IMAGE2 ...`

#### To verify the status

```bash
kubectl rollout status deployment demo
```

#### Undo

```bash
kubectl rollout undo deployment demo --dry-run

kubectl rollout undo deployment demo
```

#### Undo to specific version

```bash
kubectl rollout history deployment demo
kubectl rollout undo deployment demo --revision=1
```

#### View rollout changes

```bash
kubectl describe deployment demo | grep Image:
# Also
diff <(kubectl rollout history deploy demo --revision=1) \
     <(kubectl rollout history deploy demo --revision=2)
```

#### Scale a deployment

```bash
kubectl scale deployment demo --replicas=5
```

#### Autoscale

Between 5-10 pods, autoscale when CPU arrives to 80%

```bash
kubectl autoscale deployment demo --min=5 --max=10 --cpu-percent=80
kubectl get hpa
```

#### Pause/resume the rollout

```bash
kubectl rollout pause deployment demo
kubectl rollout resume deployment demo
```

## Notes from the Training

### Storage

**emptyDir** storage:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
spec:
  containers:
    - name: busy
      image: busybox
      command: ["sleep", "3600"]
      volumeMounts:
      - name: scratch-vol
        mountPath: /scratch
  volumes:
    - name: scratch-vol
      emptyDir: {}
```

**emptyDir** shared volume

```yaml
...
spec:
  containers:
  - name: busy
    image: busybox
    volumenMounts:
    - name: test
      mountPath: /busy
  - name: box
    image: busybox
    volumeMounts:
    - name: test
       mountPath: /box
  volumens:
  - name: test
    emptyDir: {}
```

```bash
$ kubectl exec -it busybox -c box -- touch /box/foobar
$ kubectl exec -it busybox -c busy -- ls /busy
foobar
```

**Persistent Volume** of type **hostPath**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: 10Gpv01
  labels:
    type: local
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/some/path/data01"
```

**Persistent Volume Claim** for the declared Persistent Volume

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myclaim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    request:
      storage: 8Gi
```

```yaml
kind: Pod
...
spec:
  containers:
  ...
  volumes:
  - name: test-vol
    persistentVolumeClaim:
      claimName: myclaim
```

**Persistent Volume Claim** with **rbd** of Ceph

```yaml
volumeMounts:
- name: cephpd
  mountPath: "/data/rbd"
volumes:
- name: rbdpd
  rbd:
    image: client
    monitor:
    - "10.19.14.22:6789"
    - "10.19.14.23:6789"
    - "10.19.14.24:6789"
    pool: k8s
    fsType: ext4
    readOnly: true
    user: admin
    keyring: /etc/ceph/keyring
    imageformat: "2"
    imagefeatures: "layering"
```

### Secrets

```bash
$ echo secreto | base64
c2VjcmV0bwo=
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql
data:
  password: c2VjcmV0bwo=
```

Secret as environment variable

```yaml
kind: Pod
...
spec:
  containers:
  - name: mysql
    image: mysql
    env:
    - name: MYSQL_ROOT_PASSWORD
      valueFrom:
        secretKeyRef:
          name: mysql
          key: password
```

Secret as a volume

```yaml
kind: Pod
...
spec:
  containers:
  - name: busy
    image: busybox
    command: ["sleep", "3600"]
    volumenMounts:
    - name: mysql
      mountPath: /mysqlpassword
  volumes:
  - name: mysql
    secret:
      secretName: mysql
```

```bash
kubectl exec -it busybox -- cat /mysqlpassword/password
```

### ConfigMaps

As environment variable

```yaml
kind: Pod
...
spec:
  containers:
  - name:
    env:
    - name: LEVEL
      valueFrom:
        configMapKeyRef:
          name: config
          key: special
```

As volumen

```yaml
volumes:
- name: config-vol
  configMap:
    name: config
```
