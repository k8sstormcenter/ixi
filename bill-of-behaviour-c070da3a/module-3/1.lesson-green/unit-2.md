---
kind: unit

title: Setup Kubescape

name: honeycluster-up
---

Now, we have the app deployed, 
Let's install kubescape

```git
git clone https://github.com/k8sstormcenter/honeycluster.git
cd honeycluster
git checkout 152-implement-bill-of-behaviour-demo-lab 
```

```sh
make bob
```

While we re waiting, lets move over into the other tab :tab-locator-inline{text='Explorer' name='Explorer'} and watch whats happening on our cluster.

::simple-task
---
:tasks: tasks
:name: make
---
#active
Waiting for all pods to come up

#completed
Congrats! (WIP: this check is meaningless)
::

Nice! Now, just to make sure, lets check that all kubescape pods are healthy, cause we need it to 
generate our BoB

```sh
kubectl get pods -n honey -l app.kubernetes.io/instance=kubescape
```
Next, we ll check the config on how long we are expected to wait until a profile is being produced

```sh
kubectl describe cm -n honey ks-cloud-config
kubectl get applicationprofile -A
kubectl describe RuntimeRuleAlertBinding all-rules-all-pods
```


So, you first wanna remember the exclusions that are set in the `rules`:

```yaml
  namespaceSelector:
    matchExpressions:
      - key: kubernetes.io/metadata.name
        operator: NotIn
        values:
          - kubescape
          - kube-system
          - cert-manager
          - openebs
          - kube-public
          - kube-node-lease
          - kubeconfig
          - gmp-system
          - gmp-public
          - honey
          - storm
          - lightening
  rules:
    - ruleName: Unexpected process launched
    - parameters:
        ignoreMounts: true
        ignorePrefixes:
          - /proc
          - /run/secrets/kubernetes.io/serviceaccount
          - /var/run/secrets/kubernetes.io/serviceaccount
          - /tmp
```


Couple of other important settings to be aware of that govern the anomaly detection and the
learning duration. i.e. how long we have to generate a `benign behaviour` profile. 
I chose to set these durations to be very small, as this is a demo. 
```
nodeAgent:
  name: node-agent
...

  config:
    maxLearningPeriod: 5m # duration string
    learningPeriod: 2m # duration string
    updatePeriod: 1m # duration string
    nodeProfileInterval: 1m # duration string
```

At this point, we should not have any ApplicationProfiles.

```sh
kubectl get applicationprofile -A
```
```sh
kubectl describe applicationprofile pod-ping-app 
```

<!-- ::simple-task
---
:tasks: tasks
:name: appprofempty
---
#active
Delete all application profiles in case you have any

#completed
Yay! All clear!
:: -->

Great job!
