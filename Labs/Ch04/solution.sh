#!/bin/bash

echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Solutions to Chapter 4 Labs\n"

create_job() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Job manifest from kubectl:\n"
  job_yaml=$(kubectl create job sleepy --image=busybox --dry-run=true -o yaml -- /bin/sleep 3)
  echo "${job_yaml}"
  echo

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Job:\n"
  cat <<EOJ | kubectl create -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: sleepy
spec:
  template:
    spec:
      containers:
      - command: ["/bin/sleep"]
        args: ["3"]
        image: busybox
        name: resting
      restartPolicy: Never
EOJ

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Jobs:\n"
  watch -n 5 kubectl get jobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Describe Job:\n"
  kubectl describe job sleepy

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Jobs:\n"
  kubectl get jobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete Job:\n"
  kubectl delete job sleepy
}

create_job_completion() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Job:\n"
  cat <<EOJ | kubectl create -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: sleepy
spec:
  completions: 5
  template:
    spec:
      containers:
      - command: ["/bin/sleep"]
        args: ["3"]
        image: busybox
        name: resting
      restartPolicy: Never
EOJ

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Jobs:\n"
  watch -n 2 kubectl get jobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  watch -n 2 kubectl get pods

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Describe Job:\n"
  kubectl describe job sleepy

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Jobs:\n"
  kubectl get jobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete Job:\n"
  kubectl delete job sleepy
}

create_job_parallelism() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Job:\n"
  cat <<EOJ | kubectl create -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: sleepy
spec:
  completions: 5
  parallelism: 2
  template:
    spec:
      containers:
      - command: ["/bin/sleep"]
        args: ["3"]
        image: busybox
        name: resting
      restartPolicy: Never
EOJ

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Jobs:\n"
  watch -n 2 kubectl get jobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  watch -n 2 kubectl get pods

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Describe Job:\n"
  kubectl describe job sleepy

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Jobs:\n"
  kubectl get jobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete Job:\n"
  kubectl delete job sleepy
}

create_job_activeDeadline() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Job:\n"
  cat <<EOJ | kubectl create -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: sleepy
spec:
  completions: 5
  parallelism: 2
  activeDeadlineSeconds: 15
  template:
    spec:
      containers:
      - command: ["/bin/sleep"]
        args: ["3"]
        image: busybox
        name: resting
      restartPolicy: Never
EOJ

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Jobs:\n"
  watch -n 2 kubectl get jobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  watch -n 2 kubectl get pods

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Describe Job:\n"
  kubectl describe job sleepy

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Jobs:\n"
  kubectl get jobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete Job:\n"
  kubectl delete job sleepy
}

create_cronjob() {
  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create CronJob manifest from kubectl:\n"
  job_yaml=$(kubectl create job sleepy --image=busybox --schedule="*/1 * * * *" --dry-run=true -o yaml -- /bin/sleep 3)
  echo "${job_yaml}"
  echo

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Create Job:\n"
  cat <<EOJ | kubectl create -f -
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  labels:
    run: sleepy
  name: sleepy
spec:
  concurrencyPolicy: Allow
  jobTemplate:
    spec:
      template:
        metadata:
          labels:
            run: sleepy
        spec:
          activeDeadlineSeconds: 15
          containers:
          - command: ["/bin/sleep"]
            args: ["3"]
            image: busybox
            name: sleepy
            resources: {}
          restartPolicy: OnFailure
  schedule: '*/2 * * * *'
EOJ

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Jobs:\n"
  watch -n 2 kubectl get cronjobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Pods:\n"
  watch -n 2 kubectl get jobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Describe Job:\n"
  kubectl describe cronjob sleepy

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m List Jobs:\n"
  kubectl get jobs

  echo -ne "\n\x1B[92;1m[INFO ]\x1B[0m Delete Job:\n"
  kubectl delete cronjob sleepy
}

# create_job
# create_job_completion
# create_job_parallelism
# create_job_activeDeadline
create_cronjob