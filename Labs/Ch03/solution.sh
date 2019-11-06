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
kind: PersistentVolume
metadata:
  labels:
    type: local
  name: task-pv-volume 
spec:
  accessModes:
  - ReadWriteOnce 
  capacity:
    storage: 200Mi
  hostPath:
    path: /tmp/data
  persistentVolumeReclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolume
metadata:
  labels:
    type: local
  name: registryvm
spec:
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

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Checking Docker Registry:\n"
  curl http://localhost:5000/v2/
  echo

  docker_build

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Tag Docker image to new Docker Registry\n"
  docker tag simpleapp localhost:5000/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Pushing image to new Docker Registry\n"
  docker push localhost:5000/simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete everything created:\n"
  kubectl delete -f registry_insecure.yaml
  kubectl delete -f vol.yaml
  rm -f registry_insecure.yaml vol.yaml

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete image from localhost:\n"
  docker image rm simpleapp

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete image from new Docker Registry:\n"
  docker image rm localhost:5000/simpleapp
}

# docker_build
# docker_run
docker_compose_registry_insecure
# compose_2_manifest