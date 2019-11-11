#!/bin/bash

echo "Solution to chapter 2 exercise"

check() {
  echo "Using Kubernetes from Docker Desktop ..."

  echo "Using context:"
  kubectl config current-context

  echo "Switch to Docker for Desktop context"
  kubectl config use-context docker-for-desktop

  kubectl cluster-info

  if [[ $? -ne 0 ]]; then 
    echo "[ERROR] Make sure Docker Desktop is running Kubernetes and the context selected. Or make sure kubectl point to some Kubernetes cluster"
    exit 1
  fi

  echo "Nodes:"
  kubectl get nodes

  echo "Describe nodes:"
  kubectl describe nodes
}

list_resources() {
  echo "Kubernetes API resources"
  kubectl api-resources
}

basic_pod() {
  echo "Basic Pod:"
  cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: basicpod
spec:
  containers:
  - name: webcont
    image: nginx
EOF
  sleep 5 
  
  echo "Get pods:"
  kubectl get pod

  echo "Describe pod:"
  kubectl describe pod basicpod

  echo "Delete basic pod:"
  kubectl delete pod basicpod

  echo "Get pods:"
  kubectl get pod
}

basic_pod_n_service() {
  echo "Basic Pod:"
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
EOP

  echo "Basic Service using ClusterIP (default):"
  cat <<EOS | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: basicservice
spec:
  selector:
    type: webserver
  ports:
  - protocol: TCP
    port: 80
EOS
  sleep 5

  echo "Get pods with more info:"
  kubectl get pod -o wide

  echo "Get service:"
  kubectl get service

  IPPO=$(kubectl get pod -o wide | grep basicpod | awk '{print $6}')
  echo "From a node, you can access the web page with the Pod IP: curl http://$IPPO"

  IPSVC=$(kubectl get service | grep basicservice | awk '{print $3}')
  echo "From a node, you can access the web page with the Service IP: curl http://$IPSVC"
  kubectl run curl --image=radial/busyboxplus:curl -it --rm --restart=Never -- /bin/sh -c "curl http://$IPSVC"

  echo "Delete Service:"
  kubectl delete svc basicservice

  echo "New Service using NodePort"
  cat <<EOSNP | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  name: basicservice
spec:
  selector:
    type: webserver
  type: NodePort
  ports:
  - protocol: TCP
    port: 80
EOSNP
  sleep 5

  # IPSVC=$(kubectl get service | grep basicservice | awk '{print $3}')
  PORTSVC=$(kubectl get service | grep basicservice | awk '{print $5}' | cut -d: -f2 | cut -d/ -f1)
  echo "Access web page with: curl http://localhost:$PORTSVC"
  open http://localhost:$PORTSVC

  echo "Delete Pod and Service:"
  kubectl delete pod basicpod
  kubectl delete svc basicservice
}

multi_container_pod() {
  echo "Multi-Container Pod:"
  cat <<EOPMC | kubectl create -f -
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
  - name: fdlogger
    image: fluent/fluentd
EOPMC
  sleep 5

  echo "Get pods:"
  kubectl get pod

  echo "Describe pod:"
  kubectl describe pod basicpod
}

deployment() {
  echo "Create deployment with 'create'"
  kubectl create deployment firstpod --image=nginx
  sleep 5

  echo "Get deployments, replicaset and pods:"
  kubectl get deployment,rs,pod

  echo "Describe deployment:"
  kubectl describe deployment firstpod

  POD=$(kubectl get pod | grep firstpod | awk '{print $1}')
  echo "Describe pod (name: $POD)"
  kubectl describe pod $POD

  echo "Delete deployment"
  kubectl delete deployment firstpod
  sleep 3

  echo "Get deployments, replicaset and pods:"
  kubectl get deployment,rs,pod
}

list_namespaces() {
  echo "List namespaces:"
  kubectl get namespaces

  echo "Pods in kube-system namespace:"
  kubectl get pod -n kube-system

  echo "Pods in all namespace:"
  kubectl get pod --all-namespaces
}

final() {
  kubectl get svc,pod
  kubectl create -f basic.yaml
  kubectl create -f basicservice.yaml
  sleep 10
  kubectl get svc,pod
  PORTSVC=$(kubectl get service | grep basicservice | awk '{print $5}' | cut -d: -f2 | cut -d/ -f1)
  curl http://localhost:$PORTSVC
  open http://localhost:$PORTSVC
  sleep 5
  kubectl delete svc basicservice
  kubectl delete pod basicpod
}

# check
# list_resources
# basic_pod
# basic_pod_n_service
# multi_container_pod
# deployment
# list_namespaces
final