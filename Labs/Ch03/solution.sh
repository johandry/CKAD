#!/bin/bash

echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Solutions to Chapter 3 Labs\n"

docker_build() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Docker build image:\n"
  cat <<EOD | docker build -t simpleapp -f - .
FROM python:2
ADD simple.py /
CMD [ "python", "./simple.py" ]
EOD

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Docker images:\n"
  docker images simpleapp
}

docker_run(){
  docker_build

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Docker run:\n"
  docker run -rm simpleapp
}

docker_compose_registry_insecure() {
yaml=$(cat <<EODCI
nginx:
  image: "nginx:alpine"
  ports:
    - 443:443
  links: 
    - registry:registry
  volumes: 
    - ./dockerreg/auth:/etc/nginx/conf.d
registry:
  image: registry:2
  ports:
    - 5000:5000
  volumes: 
    - ./dockerreg/data:/var/lib/registry
EODCI
)

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Docker Registry with compose up (insecure docker registry):\n"
  echo "${yaml}" | docker-compose -f - up -d

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Checking Docker Registry:\n"
  curl http://localhost:5000/v2/
  echo

  docker_build
  
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Tag Docker image to new Docker Registry\n"
  docker tag simpleapp localhost:5000/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Pushing image to new Docker Registry\n"
  docker push localhost:5000/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Checking Docker Registry Directory:\n"
  ls -al dockerreg/data/docker/registry/v2/repositories/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete image and new tagged image from localhost:\n"
  docker image rm simpleapp
  docker image rm localhost:5000/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List local images with simpleapp name:\n"
  docker images | grep simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Pull image from new Docker Registry:\n"
  docker pull localhost:5000/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete image pulled from new Docker Registry:\n"
  docker image rm localhost:5000/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Checking Docker Registry Directory:\n"
  ls -al dockerreg/data/docker/registry/v2/repositories/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Tear down Docker Registry:\n"
  echo "${yaml}" | docker-compose -f - down
}

compose_2_manifest() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Kompose version:\n"
  kompose version
  if [[ $? -ne 0 ]]; then 
    echo -ne "\n\x1B[91;1m[ERROR]\x1B[0m Install kompose with: brew install kompose\n"
    exit 1
  fi

  cat <<EODCI > docker_compose_registry_insecure.yaml
nginx:
  image: "nginx:alpine"
  ports:
    - 443:443
  links: 
    - registry:registry
  volumes: 
    - ./dockerreg/auth:/etc/nginx/conf.d
registry:
  image: registry:2
  ports:
    - 5000:5000
  volumes: 
    - ./dockerreg/data:/var/lib/registry
EODCI

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Convert Docker Compose to Kubernetes Manifest file:\n"
  kompose convert -f docker_compose_registry_insecure.yaml -o registry_insecure.yaml
  rm -f docker_compose_registry_insecure.yaml

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Volume manifests:\n"
  cat <<EOV > vol.yaml
apiVersion: v1
kind: List
metadata: {}
items:
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    labels:
      type: local
    name: task-pv-volume 
  spec:
    storageClassName: hostpath
    accessModes:
    - ReadWriteOnce 
    capacity:
      storage: 200Mi
    hostPath:
      path: /tmp/data
    persistentVolumeReclaimPolicy: Retain
- apiVersion: v1
  kind: PersistentVolume
  metadata:
    labels:
      type: local
    name: registryvm
  spec:
    storageClassName: hostpath
    accessModes:
    - ReadWriteOnce 
    capacity:
      storage: 200Mi
    hostPath:
      path: /tmp/nginx
    persistentVolumeReclaimPolicy: Retain
EOV

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Volumes:\n"
  kubectl create -f vol.yaml
  kubectl get pv

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create everything else from Docker Compose file:\n"
  kubectl create -f registry_insecure.yaml
  sleep 10

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m All created resources:\n"
  kubectl get pods,svc,pvc,pv,deploy

  SVC_REG_IP=$(kubectl get svc registry | grep registry | awk '{print $3}')
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Checking Docker Registry (http://${SVC_REG_IP}:5000/v2/):\n"
  kubectl run -it alpine --image=alpine --rm --restart=Never -- /bin/sh -c "apk update 2>&1 >/dev/null  && apk add curl 2>&1 >/dev/null; curl http://${SVC_REG_IP}:5000/v2/ && echo"
  echo

  docker_build

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Tag Docker image to new Docker Registry\n"
  docker tag simpleapp ${SVC_REG_IP}:5000/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Pushing image to new Docker Registry\n"
  docker push ${SVC_REG_IP}:5000/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete everything created:\n"
  kubectl delete -f registry_insecure.yaml
  kubectl delete -f vol.yaml
  rm -f registry_insecure.yaml vol.yaml

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete image from localhost:\n"
  docker image rm simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete image from new Docker Registry:\n"
  docker image rm localhost:5000/simpleapp
}

insecure_registry() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Creating an insecure registry:\n"
  kubectl create -f insecure_registry.yaml
  sleep 5

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m All created resources:\n"
  kubectl get pods,svc,pvc,pv,deploy

  docker_build

  SRV_PORT=$(kubectl get service registry | grep registry | awk '{print $5}' | cut -f2 -d: | cut -f1 -d/)
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Tag Docker image to new Docker Registry\n"
  docker tag simpleapp localhost:${SRV_PORT}/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Checking Docker Registry (http://localhost:${SRV_PORT}/v2/):\n"
  curl http://localhost:${SRV_PORT}/v2/
  echo

  echo -ne "\n\x1B[93;1m[WARN ]\x1B[0m Add the following insecure Docker Registry (localhost:${SRV_PORT}) to Docker config and restart it\n"
  read -n 1 -s -r -p "Press any key to continue"
  echo

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Pushing image to new Docker Registry (localhost:${SRV_PORT})\n"
  docker push localhost:${SRV_PORT}/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Deleting the insecure registry:\n"
  # kubectl delete -f insecure_registry.yaml
}

deployment() {
  docker_build

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Push Docker image to DockerHub:\n"
  docker tag simpleapp johandry/simpleapp
  docker push johandry/simpleapp

  # SRV_PORT=$(kubectl get service registry | grep registry | awk '{print $5}' | cut -f2 -d: | cut -f1 -d/)
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Creating deployment:\n"
  # kubectl create deployment try --image=localhost:${SRV_PORT}/simpleapp:latest
  kubectl create deployment try --image=johandry/simpleapp:latest

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Increasing replicas to 6:\n"
  kubectl scale deployment try --replicas=6
  sleep 5

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods & Deployments:\n"
  kubectl get pods,deployment

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Save deployment to manifest file:\n"
  kubectl get deployment try -o yaml > deployment.yaml

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Deleting deployment:\n"
  kubectl delete deployment try 
  sleep 5

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods & Deployments:\n"
  kubectl get pods,deployment

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Creating deployment from file:\n"
  kubectl create -f deployment.yaml
  sleep 5

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods & Deployments:\n"
  kubectl get pods,deployment

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Deleting deployment:\n"
  kubectl delete deployment try 

  rm deployment.yaml
}

readinessProbe() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Creating deployment:\n"
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
        imagePullPolicy: Always
        name: simpleapp
        readinessProbe:
          periodSeconds: 5
          exec:
            command:
            - cat
            - /tmp/healthy
      restartPolicy: Always
EOD
  sleep 10

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods & Deployments:\n"
  watch -n 5 kubectl get pods
  kubectl get pods,deployments

  ONE_POD=$(kubectl get pods | grep ^try- | head -1 | awk '{print $1}')
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Getting Pod '${ONE_POD}' healthy and ready:\n"
  kubectl exec ${ONE_POD} touch /tmp/healthy
  sleep 3

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  kubectl get pods

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Getting all Pods healthy and ready:\n"
  for p in $(kubectl get pods | grep ^try- | awk '{print $1}'); do
    echo -ne "\x1B[92;1m[INFO ]\x1B[0m -> Getting Pods '${p}' healthy and ready:\n"
    kubectl exec ${p} touch /tmp/healthy
  done

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  watch -n 5 kubectl get pods
  kubectl get pods

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Deleting deployment:\n"
  kubectl delete deployment try
}

livenessProbe() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Creating deployment:\n"
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
        imagePullPolicy: Always
        name: simpleapp
        readinessProbe:
          periodSeconds: 5
          exec:
            command:
            - cat
            - /tmp/healthy
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

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods & Deployments:\n"
  watch -n 5 kubectl get pods
  kubectl get pods,deployments

  ONE_POD=$(kubectl get pods | grep ^try- | head -1 | awk '{print $1}')
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Getting Pod '${ONE_POD}' healthy and ready:\n"
  kubectl exec ${ONE_POD} -c simpleapp touch /tmp/healthy
  sleep 3

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  kubectl get pods

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Getting all Pods healthy and ready:\n"
  for p in $(kubectl get pods | grep ^try- | awk '{print $1}'); do
    echo -ne "\x1B[92;1m[INFO ]\x1B[0m -> Getting Pods '${p}' healthy and ready:\n"
    kubectl exec ${p} -c simpleapp touch /tmp/healthy
  done

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  watch -n 5 kubectl get pods
  kubectl get pods

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Deleting deployment:\n"
  kubectl delete deployment try
}

# docker_build
# docker_run
# docker_compose_registry_insecure
# compose_2_manifest
# insecure_registry
# deployment
# readinessProbe
# livenessProbe