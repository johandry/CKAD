#!/bin/bash

echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Solutions to Chapter 5 Labs\n"

create_configmap() {
  kubectl delete configmap colors

  mkdir primary
  echo c > primary/cyan
  echo m > primary/magenta
  echo y > primary/yellow
  echo k > primary/black
  echo "known as key" >> primary/black
  echo blue > favorite

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create ConfigMap:\n"
  kubectl create configmap colors \
    --from-literal=text=black \
    --from-file=./favorite \
    --from-file=./primary/

  rm -rf primary favorite

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View ConfigMaps:\n"
  kubectl get configmaps

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View created ConfigMap:\n"
  kubectl get configmap colors -o yaml
}

use_configmap() {
  create_configmap

  kubectl delete deployment try

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Deployment:\n"
  cat <<EOD | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: try
  name: try
spec:
  progressDeadlineSeconds: 600
  replicas: 6
  selector:
    matchLabels:
      app: try
  template:
    metadata:
      labels:
        app: try
    spec:
      containers:
      - image: johandry/simpleapp:latest
        env:
        - name: ilike
          valueFrom:
            configMapKeyRef:
              name: colors
              key: favorite
        envFrom:
        - configMapRef:
            name: colors
        imagePullPolicy: Always
        name: simpleapp
      - image: k8s.gcr.io/goproxy:0.1
        imagePullPolicy: Always
        name: goproxy
        ports:
        - containerPort: 8080
        readinessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 20
      restartPolicy: Always
EOD

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  watch -n 5 kubectl get pods
  kubectl get pods

  POD=$(kubectl get pods | grep try | head -1 | awk '{ print $1 }')

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View environment variable \$ilike in pod $POD:\n"
  kubectl exec -c simpleapp -it $POD -- /bin/bash -c 'echo $ilike'

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View all environment variables in pod $POD:\n"
  kubectl exec -c simpleapp -it $POD -- /bin/bash -c 'env'
}

create_configmap_from_manifest() {
  kubectl delete configmap car
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create ConfigMap from Manifest:\n"
  cat <<EOCM | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: car
data:
  car.make: Ford
  car.model: Mustang
  car.trim: Shelby
EOCM

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View ConfigMaps:\n"
  kubectl get configmaps

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View created ConfigMap:\n"
  kubectl get configmap car -o yaml
}

use_configmap_from_manifest() {
  create_configmap
  create_configmap_from_manifest

  kubectl delete deployment try

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Deployment:\n"
  cat <<EOD | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: try
  name: try
spec:
  progressDeadlineSeconds: 600
  replicas: 6
  selector:
    matchLabels:
      app: try
  template:
    metadata:
      labels:
        app: try
    spec:
      containers:
      - image: johandry/simpleapp:latest
        volumeMounts:
        - mountPath: /etc/cars
          name: car-vol
        env:
        - name: ilike
          valueFrom:
            configMapKeyRef:
              name: colors
              key: favorite
        envFrom:
        - configMapRef:
            name: colors
        imagePullPolicy: Always
        name: simpleapp
        readinessProbe:
          periodSeconds: 5
          exec:
            command:
            - ls
            - /etc/cars
      - image: k8s.gcr.io/goproxy:0.1
        imagePullPolicy: Always
        name: goproxy
        ports:
        - containerPort: 8080
        readinessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 20
      volumes:
      - name: car-vol
        configMap:
          defaultMode: 420
          name: car
      restartPolicy: Always
EOD

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  watch -n 5 kubectl get pods
  kubectl get pods

  POD=$(kubectl get pods | grep try | head -1 | awk '{ print $1 }')

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View environment variable \$ilike in pod $POD:\n"
  kubectl exec -c simpleapp -it $POD -- /bin/bash -c 'echo $ilike'

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View all environment variables in pod $POD:\n"
  kubectl exec -c simpleapp -it $POD -- /bin/bash -c 'env'

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List the files created from the configMap in pod $POD:\n"
  kubectl exec -it -c simpleapp $POD -- /bin/bash -c 'ls -l /etc/cars'  

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View the files created from the configMap in pod $POD:\n"
  kubectl exec -it -c simpleapp $POD -- /bin/bash -c 'cat /etc/cars/car.*'
}

create_volumes() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Persistent Volume:\n"
  cat <<EOPV | kubectl create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-vol-1
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  hostPath:
    path: "/tmp/data"
EOPV

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List the Persistent Volumes:\n"
  kubectl get pv

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Persistent Volume Claim:\n"
  cat <<EOPVC | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-1
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 200Mi
EOPVC

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List the Persistent Volumes:\n"
  kubectl get pvc
}

use_volume() {
  kubectl delete deployment try

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Deployment:\n"
  cat <<EOD | kubectl create -f -
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: try
  name: try
spec:
  progressDeadlineSeconds: 600
  replicas: 6
  selector:
    matchLabels:
      app: try
  template:
    metadata:
      labels:
        app: try
    spec:
      containers:
      - image: johandry/simpleapp:latest
        volumeMounts:
        - mountPath: /etc/cars
          name: car-vol
        - mountPath: /tmp
          name: tmp-vol
        env:
        - name: ilike
          valueFrom:
            configMapKeyRef:
              name: colors
              key: favorite
        envFrom:
        - configMapRef:
            name: colors
        imagePullPolicy: Always
        name: simpleapp
        readinessProbe:
          periodSeconds: 5
          exec:
            command:
            - ls
            - /etc/cars
      - image: k8s.gcr.io/goproxy:0.1
        imagePullPolicy: Always
        name: goproxy
        ports:
        - containerPort: 8080
        readinessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 20
      volumes:
      - name: car-vol
        configMap:
          defaultMode: 420
          name: car
      - name: tmp-vol
        persistentVolumeClaim:
          claimName: pvc-1
      restartPolicy: Always
EOD

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  watch -n 5 kubectl get pods
  kubectl get pods

  POD=$(kubectl get pods | grep try | head -1 | awk '{ print $1 }')

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Describe Pod $POD:\n"
  kubectl describe pod $POD

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Check Volume from pod $POD:\n"
  kubectl exec -it -c simpleapp $POD -- /bin/sh -c 'ls -al /tmp/'

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create file in volumen of pod $POD:\n"
  kubectl exec -it -c simpleapp $POD -- /bin/sh -c 'echo "test from pod" > /tmp/test.txt'

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Check file in volumen from localhost:\n"
  cat /tmp/data/test.txt

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Update file from localhost:\n"
  echo "second test" >> /tmp/data/test.txt

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Checking file in volumen from pod $POD:\n"
  kubectl exec -it -c simpleapp $POD -- /bin/sh -c 'cat /tmp/test.txt'
}

create_basicpod() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create local host path:\n"
  mkdir -f /tmp/weblog

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Persistent Volume:\n"
  cat <<EOP | kubectl create -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: weblog-pv-vol
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/tmp/weblog"
EOP

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Verify Persistent Volume:\n"
  kubectl get pv weblog-pv-vol

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Persistent Volume Claim:\n"
  cat <<EOP | kubectl create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: weblog-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
EOP

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Verify Persistent Volume Claim:\n"
  kubectl get pvc weblog-pv-claim

  kubectl delete cm fluentd-config
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create ConfigMap for fluentd:\n"
  cat <<EOCM | kubectl create -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluentd.conf: |
    <source>
      @type tail
      format none
      path /var/log/nginx/access.log 
      tag count.format1
    </source>

    <match *.**> 
      @type forward

      <server>
        name localhost 
        host 127.0.0.1
      </server>
    </match>
EOCM

  kubectl delete pod basicpod
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Pod with Volume & config'ed fluentd:\n"
  cat <<EOP | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: basicpod
  labels:
    type: webserver
spec:
  containers:
  - name: webcont
    image: nginx
    ports:
      - containerPort: 80
    volumeMounts:
      - mountPath: "/var/log/nginx"
        name: weblog-pv-storage
  - name: fdlogger
    image: fluent/fluentd
    env:
    - name: FLUENTD_ARGS
      value: -c /etc/fluentd-config/fluentd.conf
    volumeMounts:
      - mountPath: "/var/log"
        name: weblog-pv-storage
      - mountPath: "/etc/fluentd-config"
        name: log-config
  volumes:
  - name: weblog-pv-storage
    persistentVolumeClaim:
      claimName: weblog-pv-claim
  - name: log-config
    configMap:
      name: fluentd-config
EOP
  watch -n 5 kubectl get po basicpod

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Verify local host storage:\n"
  ls -al /tmp/weblog

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Verify Pod storage in both containers:\n"
  kubectl exec -it -c webcont  basicpod -- /bin/bash -c 'ls -al /var/log/nginx'
  kubectl exec -it -c fdlogger basicpod -- /bin/sh   -c 'ls -al /var/log'

  IP=$(kubectl get po basicpod -o wide | grep basicpod | awk '{print $6}')
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Verify the web service:\n"
  kubectl run busybox --rm -it --restart=Never --image=busybox -- wget -O- $IP:80

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Check pod logs:\n"
  kubectl logs basicpod fdlogger
}

docker_build() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Modify the code or the Docker image:\n"
  sed 's/sleep(5)/sleep(8)/' ../Ch03/simple.py > simple.py

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Docker build image:\n"
  cat <<EOD | docker build -t simpleapp -f - .
FROM python:2
ADD simple.py /
CMD [ "python", "./simple.py" ]
EOD
  
  rm -f simple.py

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Docker images:\n"
  docker images simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Tag image as version 2:\n"
  docker tag simpleapp johandry/simpleapp:v2

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Pushing version 2:\n"
  docker push johandry/simpleapp:v2
}

rollout() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Modify the code or the Docker image:\n"
  # export KUBE_EDITOR=vim
  # kubectl edit deployment try
  kubectl set image deploy try simpleapp=johandry/simpleapp:v2

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View update:\n"
  watch -n 5 kubectl get pods

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View events:\n"
  kubectl get events

  POD=$(kubectl get pods | grep try | head -1 | awk '{print $1}')
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View images in pod $POD:\n"
  kubectl describe pod try-7b7f46984c-7ggmg | grep Image:

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Rollout history:\n"
  kubectl rollout history deployment try

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Different between revision 1 and 2:\n"
  diff <(kubectl rollout history deployment try --revision=1) <(kubectl rollout history deployment try --revision=2)

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m What whould be done if we restore replica #1:\n"
  kubectl rollout undo deployment try --dry-run

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Rollback to replica #1:\n"
  kubectl rollout undo deployment try --to-revision=1

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View rollback:\n"
  watch -n 5 kubectl get pods
}

# create_configmap
# use_configmap
# create_configmap_from_manifest
# use_configmap_from_manifest
# create_volumes
use_volume
# create_basicpod
# docker_build
rollout