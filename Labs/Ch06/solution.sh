#!/bin/bash

echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Solutions to Chapter 6 Labs\n"

create_app2() {
  # mkdir app2
  # cd app2

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Use this command to generate part of the Pod for the app2:\n"
  echo "kubectl run app2 --image=busybox --dry-run -o yaml --restart=Never --overrides='{\"spec\": {\"securityContext\": {\"runAsUser\": 1000}}}' --command -- sleep 3600"
  kubectl run app2 --image=busybox --dry-run -o yaml --restart=Never --overrides='{"spec": {"securityContext": {"runAsUser": 1000}}}' --command -- sleep 3600
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Append this to the container:\n"
  cat <<EOSC
    securityContext:
      runAsUser: 2000
      allowPrivilegeEscalation: false
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
EOSC

  kubectl delete pod app2
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create a Pod for the app2:\n"
  cat <<EOA2 | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: app2
  name: app2
spec:
  securityContext:
    runAsUser: 1000
  containers:
  - command:
    - sleep
    - "3600"
    image: busybox
    name: app2
    securityContext:
      runAsUser: 2000
      allowPrivilegeEscalation: false
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
EOA2

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Check the Pod for the app2:\n"
  watch kubectl get pod app2

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Check processes in Pod app2:\n"
  kubectl exec app2 -- ps aux

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Check kernel capabilities in Pod app2:\n"
  kubectl exec app2 -- grep Cap /proc/1/status

  cap=$(kubectl exec app2 -- grep CapInh /proc/1/status | awk '{print $2}')
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Check the capability ${cap}:\n"
  kubectl run capsh --image=debian --rm -it --restart=Never -- /sbin/capsh --decode=${cap}
}

create_secret() {
  p='M!Pa55w0rd'
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Secret with password = ${p}. Base64 Encrypted: $(echo $p | base64):\n"
  kubectl create secret generic appsecret --from-literal=password=$p --dry-run -o yaml

  kubectl delete secret appsecret
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create secret with password = ${p}:\n"
  cat <<EOS | kubectl create -f -
apiVersion: v1
kind: Secret
metadata:
  name: appsecret
data:
  password: TSFQYTU1dzByZAo=
EOS

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List secrets and describe appsecret:\n"
  kubectl get secrets
  echo "----"
  kubectl describe secret appsecret

  kubectl delete pod app2
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create a Pod for the app2 with the new secret:\n"
  cat <<EOA2 | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: app2
  name: app2
spec:
  securityContext:
    runAsUser: 1000
  containers:
  - name: app2
    image: busybox
    command:
    - sleep
    - "3600"
    securityContext:
      runAsUser: 2000
      allowPrivilegeEscalation: false
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
    volumeMounts:
    - name: mysql
      mountPath: /mysqlpassword
  volumes:
  - name: mysql
    secret:
      secretName: appsecret
EOA2
  watch kubectl get pod app2
}

check_secret(){
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m View secrets inside container:\n"
  kubectl exec app2 -it -- sh -c "ls -al /mysqlpassword; echo; echo -n 'Password: '; cat /mysqlpassword/password; echo"
}

create_service_account() {
  kubectl delete rolebinding secret-access-rb
  kubectl delete clusterrole secret-access-cr
  kubectl delete sa secret-access-sa

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Secrets:\n"
  kubectl get secrets --all-namespaces

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create the Service Account 'secret-access-sa':\n"
  cat <<EOSA | kubectl create -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: secret-access-sa
EOSA

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Service Accounts:\n"
  kubectl get serviceaccounts

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create the Cluster Role 'secret-access-cr':\n"
  cat <<EOCR | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: secret-access-cr
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - list
EOCR

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Cluster Roles:\n"
  kubectl get clusterroles

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Bind the Service Account to the Cluster Role:\n"
  cat <<EORB | kubectl create -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-access-rb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: secret-access-cr
subjects:
- kind: ServiceAccount
  name: secret-access-sa
EORB

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Role Bindings:\n"
  kubectl get rolebindings

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Pod Service Account before set 'secret-access-sa':\n"
  kubectl describe pod app2 | grep -i secret
  kubectl delete pod app2

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Recreate Pod with Service Account 'secret-access-sa':\n"
    cat <<EOA2 | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: app2
  name: app2
spec:
  serviceAccountName: secret-access-sa
  securityContext:
    runAsUser: 1000
  containers:
  - name: app2
    image: busybox
    command:
    - sleep
    - "3600"
    securityContext:
      runAsUser: 2000
      allowPrivilegeEscalation: false
      capabilities:
        add: ["NET_ADMIN", "SYS_TIME"]
    volumeMounts:
    - name: mysql
      mountPath: /mysqlpassword
  volumes:
  - name: mysql
    secret:
      secretName: appsecret
EOA2
  watch kubectl get pod app2

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Pod Service Account after set 'secret-access-sa':\n"
  kubectl describe pod app2 | grep -i secret
}

# create_app2
# create_secret
check_secret
create_service_account
