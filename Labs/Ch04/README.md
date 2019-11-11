# Chapter 4: Design

##### Documentation

Go to kubernetes.io -> Tasks -> Run Jobs -> [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/)

##### Create a job

```bash
kubectl run sleepy --image=busybox --restart=OnFailure --dry-run=true -o yaml -- /bin/sleep 3
# Or
kubectl create job sleepy --image=busybox --dry-run=true -o yaml -- /bin/sleep 3
```

##### Completion, Parallelism & Active Deadline

Edit the job manifest to include `job.spec.completion`, `job.spec.parallelism` and `job.spec.activeDeadlineSeconds`. Example:

```yaml
spec:
  completions: 5
  parallelism: 2
  activeDeadlineSeconds: 15
  template:
    spec:
```

##### Create a cronjob

```bash
kubectl run sleepy --image=busybox --schedule="*/2 * * * *" --restart=OnFailure --dry-run=true -o yaml -- /bin/sleep 3
```

## Links in training

- [Ambassador](https://www.getambassador.io) is an "open source, Kubernetes-native API gateway for microservices built on Enjoy"
