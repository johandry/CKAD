# Chapter 6: Security

#### Documentation

* kubernetes.io > Reference > Accessing the API > [Controlling Access to the Kubernetes API](https://kubernetes.io/docs/reference/access-authn-authz/controlling-access/)
* kubernetes.io > Reference > Accessing the API > [Authenticating](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)
* kubernetes.io > Tasks > Configure Pods and Containers > [Configure a Security Context for a Pod or Container](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
* kubernetes.io > Concepts > Services, Load Balancing, and Networking > [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

#### Security Context

A pod that runs with user id 101

```bash
kubectl run nginx --image=nginx --restart=Never --dry-run -o yaml > nginx.yaml
```

Insert `Pod.spec.securityContext.runAsUser`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  securityContext:
    runAsUser: 101
  containers:
    ...
```

Make it has the capabilities `NET_ADMIN` and `SYS_TIME`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  securityContext:
    runAsUser: 101
    capabilities:
      add: ["NET_ADMIN", "SYS_TIME"]
  containers:
    ...
```

#### Network Policies

List of network providers that supports Network Policy:

kubernetes.io > Tasks > Administer a Cluster > Install a Network Policy Provider > Declare Network Policy > [Before you begin](https://kubernetes.io/docs/tasks/administer-cluster/declare-network-policy/#before-you-begin)

Network policy to allow access to the pod only if other pods are labeled with `access: true`

```bash
kubetcl run nginx --image=nginx --replicas=2 --port=80 --expose
kubectl get svc nginx -o yaml # get the pod selector label: 'run: nginx' or use:
kubectl get po --show-labels | grep nginx # check with:
kubectl get po -l run=nginx
```

Network Policy:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: access
spec:
  podSelector:
    matchLabels:
      run: nginx    # label of the pod to apply the rule
  policyType:
    - Ingress
  igress:
    - from
      - podSelector:
        matchLabels:
          access: true
```

Check:

```bash
# Access denied
kubectl run busybox --image=busybox --rm -it --restart=Never -- wget -O- http://nginx:80

# Access granted
kubectl run busybox --image=busybox --rm -it --restart=Never --labels=access=true -- wget -O- http://nginx:80
```

### Notes from the Training

![Access Control Overview](https://kubernetes.io/images/docs/admin/access-control-overview.svg)

#### Example of authorization policy file

```json
{
  "apiVersion": "abac.authorization.kubernetes.io/v1beta1",
  "kind": "Policy",
  "spec": {
    "user": "bob",
    "namespace": "foobar",
    "resource": "pods",
    "readonly": true
  }
}
```

More examples in:

kubernetes.io > Reference > Accessing the API > [Using ABAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/abac/)

##### Policy example using `securityContext`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - image: nginx
    name: nginx
```

Know more about [Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

##### Pod Security Policy (PSP) example

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  runAsUser:
    rule: MustRunAsNonRoot
  fsGroup:
    rule: RunAsAny
```

More examples of [PodSecurityPolicy](https://github.com/kubernetes/examples/tree/master/staging/podsecuritypolicy/rbac)

##### Network Security Policy example

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-egress-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
      - ipBlock:
          cidr: 172.17.0.0/16
          except:
            - 172.17.1.0/24
    - namespaceSelector:
        matchLabels:
          project: myproject
    - podSelector:
        matchLabels:
          role: frontend
    ports:
      - protocol: TCP
        port: 6379
  egress:
    - to:
      - ipBlock:
          cidr: 10.0.0.0/24
      ports:
        - protocol: TCP
          port: 5978
```

Example of complex match expression:

```yaml
podSelector:
  matchExpression:
    - {key: inns, operator: In, values: ["yes"]}
```

More examples of [Network Policies](https://github.com/ahmetb/kubernetes-network-policy-recipes)
