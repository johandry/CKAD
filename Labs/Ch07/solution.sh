#!/bin/bash

echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Solutions to Chapter 7 Labs\n"

create_service_clusterIP() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Use this generator for the service:\n"
  echo "kubectl create service clusterip app2 --tcp=80 --dry-run -o yaml"
  kubectl create service clusterip app2 --tcp=80 --dry-run -o yaml
  
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Recreate the service with type ClusterIP:\n"
  kubectl delete service app2
  cat <<EOSC | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: app2
  name: app2
spec:
  ports:
  - name: "80"
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: app2
  type: ClusterIP
EOSC

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List all services:\n"
  kubectl get services

  clusterIP=$(kubectl get service app2 -o jsonpath='{$.spec.clusterIP}')
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Test the service using the ClusterIP ${clusterIP}:\n"
  kubectl run busybox --image=busybox -it --rm --restart=Never -- sh -c "wget -q -O- http://${clusterIP}:80 | head -10"
}

create_service_nodePort() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Use this generator for the service:\n"
  echo "kubectl create service nodeport app2 --tcp=80 --node-port=32000 --dry-run -o yaml"
  kubectl create service nodeport app2 --tcp=80 --node-port=32000 --dry-run -o yaml
  
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Recreate the service with type NodePort:\n"
  kubectl delete service app2
  cat <<EOSC | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: app2
  name: app2
spec:
  ports:
  - name: "80"
    nodePort: 32000
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: app2
  type: NodePort
EOSC

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List all services:\n"
  kubectl get services

  clusterIP=$(kubectl get service app2 -o jsonpath='{$.spec.clusterIP}')
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Test the service using the ClusterIP ${clusterIP}:\n"
  kubectl run busybox --image=busybox -it --rm --restart=Never -- sh -c "wget -q -O- http://${clusterIP}:80 | head -10"

  echo -ne "\n\x1B[93;1m[WARN ]\x1B[0m For Kubernetes on Docker for Desktop use 'localhost' to access the node\n"
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Test the service using the NodePort:\n"
  curl -s http://localhost:32000 | head -10
}

create_service_loadBalancer() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Use this generator for the service:\n"
  echo "kubectl create service loadbalancer app2 --tcp=80 --dry-run -o yaml"
  kubectl create service loadbalancer app2 --tcp=80 --dry-run -o yaml
  echo "Optionally add: 'nodePort: 32000' to 'Service.spec.ports[0]'"
  
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Recreate the service with type NodePort:\n"
  kubectl delete service app2
  cat <<EOSC | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: app2
  name: app2
spec:
  ports:
  - name: "80"
    nodePort: 32000
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: app2
  type: LoadBalancer
EOSC

  echo -ne "\n\x1B[93;1m[WARN ]\x1B[0m For some clusters there is no LoadBalancer provider, keeping the EXTERNAL-IP as <pending>\n"
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List all services:\n"
  kubectl get services

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List all Endpoints:\n"
  kubectl get ep

  clusterIP=$(kubectl get service app2 -o jsonpath='{$.spec.clusterIP}')
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Test the service using the ClusterIP ${clusterIP}:\n"
  kubectl run busybox --image=busybox -it --rm --restart=Never -- sh -c "wget -q -O- http://${clusterIP}:80 | head -10"

  echo -ne "\n\x1B[93;1m[WARN ]\x1B[0m For Kubernetes on Docker for Desktop use 'localhost' as LoadBalancer IP for the LB Service"
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Test the service using the NodePort localhost:32000:\n"
  curl -s http://localhost:32000 | head -10
  
  epPort=$(kubectl get ep app2 -o jsonpath='{$.subsets[0].ports[0].port}')
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Test the service using the LoadBalancer and port $lbPort:\n"
  curl -s http://localhost:${epPort} | head -10
}

create_ClusterRole_n_Binding() {
  kubectl delete clusterrole traefik-ingress-controller
  kubectl delete clusterrolebinding traefik-ingress-controller

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Cluster Role and Binding:\n"
  kubectl create -f ingress.rbac.yml

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Apply Traefik manifests:\n"
  kubectl apply -f traefik-ds.yaml

  echo -ne "\n\x1B[93;1m[WARN ]\x1B[0m Download Traefik from https://github.com/containous/traefik/releases\n" 
}

create_ingress() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create the Ingress:\n"
  kubectl delete ingress test-ingress
  cat <<EOI | kubectl create -f -
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: traefik
spec:
  rules:
  - host: www.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: app2
          servicePort: 80
EOI

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Ingress:\n"
  kubectl get ingresses
}

# create_service_clusterIP
# create_service_nodePort
# create_service_loadBalancer
# create_ClusterRole_n_Binding
create_ingress