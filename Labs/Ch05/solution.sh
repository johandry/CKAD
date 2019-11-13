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

# create_configmap
# use_configmap
# create_configmap_from_manifest
use_configmap_from_manifest
