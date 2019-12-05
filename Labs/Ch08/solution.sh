#!/bin/bash

echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Solutions to Chapter 8 Labs\n"

check_pods() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Checking Pods:\n"
  kubectl get pods

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Checking Pods not Running:\n"
  kubectl get pods | grep -v Running

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Describe Pod app2:\n"
  kubectl describe pod app2

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Print Pod app2 conditions:\n"
  kubectl describe pod app2 | grep Conditions -A5

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Print Pod app2 events:\n"
  kubectl describe pod app2 | grep Events -A1000

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Print container webserver logs:\n"
  kubectl logs app2 webserver

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Print container app2 logs:\n"
  kubectl logs app2 app2

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Check access to outside world:\n"
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m nslookup & /etc/resolv.conf:\n"
  kubectl exec app2 -c app2 -it -- sh -c "nslookup www.johandry.com; echo '---'; cat /etc/resolv.conf"
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m netcat:\n"
  kubectl exec app2 -c app2 -it -- sh -c "nc -vz johandry.github.io"
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m wget:\n"
  kubectl exec app2 -c app2 -it -- sh -c "wget -O- www.johandry.com | head -3"

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Check Service-Pod relationship:\n"
  kubectl get services
  # echo
  # kubectl get service app2 -o yaml
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Service selector for app2:\n"
  kubectl get service app2 -o yaml | grep selector -A1
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Check Endpoints-Service relationship:\n"
  kubectl get ep
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Endpoints for app2:\n"
  kubectl get ep app2 -o yaml
}

check_not_running_pods() {
  notRunning=$(kubectl get pods --all-namespaces | grep -v Running | grep -v NAME | head -1 | awk '{print $2," -n ",$1}')
  if [[ -n $notRunning ]]; then
    echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Describe Pod not Running $(echo $notRunning | cut -f1 -d' '):\n"
    kubectl describe pod $notRunning

    echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Display events of Pod not Running $(echo $notRunning | cut -f1 -d' '):\n"
    kubectl get events -n $(echo $notRunning | awk '{print $3}')
  fi
}

check_pods
# check_not_running_pods