## Chapter 8: Troubleshooting

### Documentation

kubernetes.io > Concepts > Cluster Administration > [Logging Architecture](https://kubernetes.io/docs/concepts/cluster-administration/logging/)

kubernetes.io > Tasks > Monitoring, Logging, and Debugging > [Logging Using Elasticsearch and Kibana](https://kubernetes.io/docs/tasks/debug-application-cluster/logging-elasticsearch-kibana/)

kubernetes.io > Tasks > Monitoring, Logging, and Debugging > [Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/troubleshooting/)

kubernetes.io > Tasks > Monitoring, Logging, and Debugging > [Troubleshoot Applications](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-application/)

kubernetes.io > Tasks > Monitoring, Logging, and Debugging > [Troubleshoot Clusters](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-cluster/)

kubernetes.io > Tasks > Monitoring, Logging, and Debugging > [Debug Pods and ReplicationControllers](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-pod-replication-controller/)

kubernetes.io > Tasks > Monitoring, Logging, and Debugging > [Debug Services](https://kubernetes.io/docs/tasks/debug-application-cluster/debug-service/)

kubernetes.io > Tasks > Monitoring, Logging, and Debugging > 

kubernetes.io > Tasks > Monitoring, Logging, and Debugging > 

### Notes from the Training

#### Linux tools

- Shell into the failing Pod/container
- Deploy similar Pod/container with busybox
- DNS: `dig`
- `tcpdump`

#### Monitoring & Logging tools

* [Prometheus](https://www.prometheus.io/) for monitoring
* [Grafana](https://grafana.com) for visualization of collected metrics from Prometheus.

* [Fluentd](https://www.fluentd.org/) for logging and feed aggregated logs to Elasticsearch

* [ELK](https://www.elastic.co/videos/introduction-to-the-elk-stack) stack of Elastisearch, ~~Logstach~~ and Kibana. Elasticserch received the aggregated logs from fluentd and use Kibana to visualize them.

  ![ELK-EFK-architecture](https://i2.wp.com/www.techmanyu.com/wp-content/uploads/ELK-EFK-architecture.jpg?fit=700%2C311&ssl=1)

* [OpenTracing](https://opentracing.io/docs/) propagate transaction among all services, code and packages. 

* [Jaeger](https://www.jaegertracing.io/) is a tracing system focus on distributed context propagation, transaction monitoring and root cause analysis. It's an implementation of OpenTracing.

#### Basic Steps

Assuming a problematic pod:

```bash
kubectl create deployment problem --image=nginx
```

In the following flow, `<tab>` means pressing `tab` key, and it's used to autocomplete the pod name.

1. Investigate errors from command line

   ```bash
   kubectl exec -it problem-<tab> -- /bin/bash
   ```

2. If the pod is running, check the logs:

   ```bash
   kubectl logs problem-<tab>
   ```

   Consider deploy a **sidecar** container in the pod to generate and handling logging. These can be configured to stream logs or run a logging agent.

3. Check networking, including DNS, firewalls and general connectivity using Linux commands/tools, example `dig`.

4. Check RBAC, SELinux and AppArmor for security settings. These may cause problems with networking.

5. Check nodes logs for errors. Make sure they have enough resources allocated.

6. API calls to and from controllers to `kube-apiserver`

7. Inter-node network issues, DNS & Firewall

8. Master server controllers. 

   1. Control Pods state
   2. Errors in log files
   3. Sufficient resources

#### Basic Flow: Pods

1. From the basic steps, execute steps #1 to #3

2. Is the containerized application working as expected?

   Confirm the app is working correctly, check if this is an intermittent issue or related to slow performance.

3. (The app is not the culprit). Make sure the Pods are in **Running** status:

   ```bash
   kubectl get pods
   ```

   The status `Pending` usually means a resource is not available from the cluster. Examples: a properly tainted node, expected storage or enough resources.

4. Look at the logs and events of the container

   ```bash
   kubectl logs problem-<tab>
   kubectl describe problem-<tab>
   kubectl get events
   ```

   Check the number of restarts. If the restarts are not caused by the command that finished, it may indicate the application is having issues and failing.

5. If there is no info in the events, check the container logs

   ```bash
   kubectl logs problem-<tab> <container_name>
   ```

#### Basic Flow: Node & Security

1. Disable security for testing. Disable RBAC, SELinux and AppArmor to identify the root cause of the issue

2. Check system and agent logs. 

   1. If they use **systemd**: Logs will go to **journalctl**, view the logs with `journalctl -a` and maybe in `/var/log/journal/`
   2. Without **systemd**: Logs created in `/var/log/<agent>.log`

   In both cases, the logs could have rotation, if not it's advisable to do it.



Container components:

* `kube-scheduler`
* `kube-proxy`

Non-container components:

* `kubelet`
* Docker
* Others ...

#### Certified Kubernetes Conformance Program

A CNCF program to certify distributions that meets essential requirements and adhere to complete API functionality. 

Read more about it on GitHub [cncf/k8s-conformance](https://github.com/cncf/k8s-conformance) and the [instructions](https://github.com/cncf/k8s-conformance/blob/master/instructions.md).

#### More resources

- [GitHub website for issues and bug tracking](https://github.com/kubernetes/kubernetes/issues)

#### 