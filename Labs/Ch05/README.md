# Chapter 5: Deployment Configuration

**Documentation**

kubernetes.io -> Tasks -> Configure Pods and Containers -> [Configure a Pod to Use a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)

**Create ConfigMap from values, files and directories**

```bash
echo -e "key1=value1\nkey2=value2" > /path/to/file

kubectl create configmap config \
	--from-literal=akey=avalue \
	--from-file=/path/to/file \
	--from-file=/path/to/dir/
```

**View ConfigMap**

```bash
kubectl get configmap config -o yaml
# Or
kubectl describe configmap config
```

**Use the ConfigMap as environment variable**

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
    - name: config				# env var name
    	valueFrom:
    		configMapKeyRef:
    			name: config 		# configmap name
    			key: akey				# key name in the cm. If ignored, will get all
  dnsPolicy: ClusterFirst
  restartPolicy: Never
status: {}
```

```bash
kubectl create -f pod.yaml
kubectl exec -it nginx -- env
```

**Use the ConfigMap as volume**



## From Taining

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

**Persistent Volumen** of type **hostPath**

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

**Persistent Volume Claim** 

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

**Secrets**

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

**ConfigMaps**

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

