---
kind: unit

title: Setup Kubescape

name: debug-2
---

Now, we have the app deployed, lets keep the loop looping and switch back to the original tab.

Let's install kubescape

```
cd
cd honeycluster
```

```sh
make bob
```

While we re waiting, lets move over into the other tab :tab-locator-inline{text='Explorer' name='Explorer'} and watch whats happening on our cluster.



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
    # CHECK that the following is NOT in your file
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

While waiting for those 2 Minutes, we should not have any ApplicationProfiles.

```sh
kubectl get applicationprofile -A
```
and eventually, you ll see something like:
```json
NAMESPACE   NAME         CREATED AT
default     replicaset-webapp-59bb57d675   2025-04-16T13:58:34Z
```
Now, you may switch of the looping in the other tab and look at generated profile
```sh
export rs=$(kubectl get replicaset -n default -o jsonpath='{.items[0].metadata.name}')
kubectl describe applicationprofile replicaset-$rs
```

AND: low and behold, it is incorrect ... because the startup of the app was never recorded therein.
In the repo, you ll find lots of profiles of the same ping app, and they are `way longer`.

<!-- -- ::simple-task
---
:tasks: tasks
:name: appprofempty
---
#active
Delete all application profiles in case you have any

#completed
Yay! All clear!
::  -->

__Question__ : Why does kubescape on k0s not receive the ExecEvents?

Some commands to reproduce/debug:




deploy some random app while tailing the logs : it wont see it

```
kubectl create ns nginx
kubectl create deployment --image=nginx nginx -n nginx
``` 

```
kubectl logs -n honey node-agent-xxx
```
or
```
kubectl logs -n honey -l app=node-agent -f -c node-agent
```

will always look like this:
```json
{"level":"error","ts":"2025-04-24T09:31:04Z","msg":"error getting cloud metadata","error":"unknown cloud provider for node k0s-01: "}
{"level":"info","ts":"2025-04-24T09:31:04Z","msg":"exporters initialized"}
time="2025-04-24T09:31:04Z" level=info msg="using the detected container runtime socket path from Kubelet's config: /run/k0s/containerd.sock"
{"level":"info","ts":"2025-04-24T09:31:04Z","msg":"IG Kubernetes client created","client":{"RuntimeConfig":{"Name":"containerd","SocketPath":"/host/run/k0s/containerd.sock","RuntimeProtocol":"cri","Extra":{"Namespace":""}}}}
{"level":"info","ts":"2025-04-24T09:31:04Z","msg":"detected container runtime","containerRuntime":"containerd"}
{"level":"info","ts":"2025-04-24T09:31:05Z","msg":"start monitor on container","container ID":"41accc00820af1a7009b72ee0077158f3aa09f5a40c48eea19847fd95dc84551","k8s workload":"default/webapp-59bb57d675-zjgqc/ping-app","ContainerImageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d","ContainerImageName":"docker.io/amitschendel/ping-app:latest"}
{"level":"info","ts":"2025-04-24T09:31:05Z","msg":"started syscall tracing"}
{"level":"info","ts":"2025-04-24T09:31:05Z","msg":"started exec tracing"}
{"level":"info","ts":"2025-04-24T09:31:05Z","msg":"started open tracing"}
{"level":"info","ts":"2025-04-24T09:31:06Z","msg":"started dns tracing"}
{"level":"info","ts":"2025-04-24T09:31:06Z","msg":"started network tracing"}
{"level":"info","ts":"2025-04-24T09:31:06Z","msg":"started capabilities tracing"}
{"level":"info","ts":"2025-04-24T09:31:07Z","msg":"started randomx tracing"}
{"level":"info","ts":"2025-04-24T09:31:07Z","msg":"started symlink tracing"}
{"level":"info","ts":"2025-04-24T09:31:07Z","msg":"started hardlink tracing"}
{"level":"info","ts":"2025-04-24T09:31:07Z","msg":"started ssh tracing"}
{"level":"info","ts":"2025-04-24T09:31:07Z","msg":"started ptrace tracing"}
{"level":"info","ts":"2025-04-24T09:31:07Z","msg":"started io_uring tracing"}
{"level":"info","ts":"2025-04-24T09:31:07Z","msg":"started http tracing"}
{"level":"info","ts":"2025-04-24T09:31:07Z","msg":"main container handler started"}
{"level":"info","ts":"2025-04-24T09:31:12Z","msg":"RBCache - ruleBinding added/modified","name":"/all-rules-all-pods"}
{"level":"info","ts":"2025-04-24T09:33:05Z","msg":"stop monitor on container - monitoring time ended","container ID":"41accc00820af1a7009b72ee0077158f3aa09f5a40c48eea19847fd95dc84551","k8s workload":"default/webapp-59bb57d675-zjgqc/ping-app"}
```
which shows us that it picks up the already running `webapp` BUT not anything else

That nginx deployment will not be picked up... (I ve tried annotations, settings, ... didnt find anything)

```
kubectl get applicationprofiles.spdx.softwarecomposition.kubescape.io 
...
nothing
```


__UNLESS__ you restart the node-agent, then however itll be missing the startup of the nginx:

```sh
kubectl rollout restart ds -n honey node-agent 
```
now, you ll see the nginx BEFORE the regular tracing 

```json
{"level":"info","ts":"2025-04-24T09:49:28Z","msg":"IG Kubernetes client created","client":{"RuntimeConfig":{"Name":"containerd","SocketPath":"/host/run/k0s/containerd.sock","RuntimeProtocol":"cri","Extra":{"Namespace":""}}}}
{"level":"info","ts":"2025-04-24T09:49:28Z","msg":"detected container runtime","containerRuntime":"containerd"}
{"level":"info","ts":"2025-04-24T09:49:28Z","msg":"start monitor on container","container ID":"d8ff80155c3e84a3dadc41d2904e0d49530f1cd8e896206005cfe2755679547c","k8s workload":"nginx/nginx-5869d7778c-wsd6v/nginx","ContainerImageDigest":"sha256:5ed8fcc66f4ed123c1b2560ed708dc148755b6e4cbd8b943fab094f2c6bfa91e","ContainerImageName":"docker.io/library/nginx:latest"}
{"level":"info","ts":"2025-04-24T09:49:28Z","msg":"start monitor on container","container ID":"41accc00820af1a7009b72ee0077158f3aa09f5a40c48eea19847fd95dc84551","k8s workload":"default/webapp-59bb57d675-zjgqc/ping-app","ContainerImageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d","ContainerImageName":"docker.io/amitschendel/ping-app:latest"}
{"level":"info","ts":"2025-04-24T09:49:28Z","msg":"started syscall tracing"}
{"level":"info","ts":"2025-04-24T09:49:29Z","msg":"started exec tracing"}
{"level":"info","ts":"2025-04-24T09:49:29Z","msg":"started open tracing"}
...
```

and eventually now you ll get another incomplete profile
```sh
laborant@k0s-01:honeycluster$ kubectl get applicationprofile -A
NAMESPACE   NAME                           CREATED AT
default     replicaset-webapp-59bb57d675   2025-04-24T09:33:05Z
nginx       replicaset-nginx-5869d7778c    2025-04-24T09:51:29Z
```