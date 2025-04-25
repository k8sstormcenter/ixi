---
kind: unit

title: Profiling with Kubescape

name: honeycluster-up
---

Now, we are still the vendor and have the `webapp` deployed on our cluster. 
We are producing `benign` traffic that triggers all known behaviour of our `webapp`

Viktor made a video of this feature, so if you dont know kubescape, consider watching https://www.youtube.com/watch?v=xilNX_mh6vE 

::remark-box
---
kind: warning
---
__IRL__: the vendor needs to ensure that all application and network behaviour during a normal productive usecase
are being triggered. Usually, this would be a combo between integration, load and behaviour-driven tests. Maybe UX test
or traffic replay.

::


We have installed `kubescape` (see the Makefile for details), it will help us use `eBPF/Inspector Gadget` in a hands-off manner via its nodeagent-component. So  we'll use a config that only installs the runtime-behaviour module produce an output that an end-user can directly consume, without having to deal with inspector gadget or ebpf or low-level stuff.

```sh
kubectl get pods -n honey -l app.kubernetes.io/instance=kubescape
```
<div style="background-color: #f0f8ff; border: 1px solid #ccc; padding: 10px; border-radius: 5px;">

__Optional__:

While waiting for all pods to be ready, you could spend the time playing with the UI `k9s`

<!-- and if you're the graphical type, you can move over into the other tab :tab-locator-inline{text='Explorer' name='Explorer'} and watch what's happening on the cluster.

I DON'T recommend the Explorer on the 3-node kubernetes cluster, its too slow -> works well on `k0s` though... -->


</div>


<!-- ::simple-task
---
:tasks: tasks
:name: make
---
#active
Waiting for all pods to come up

#completed
Congrats! 
:: 

You can watch the pods becoming blue and select those items you d like to `watch` with the `eye` icon.
-->
 <!-- ::image-box
---
:src: module-1/lesson-1/img/explorer.png
:alt: 'This image is still not found - Known issue'
---
:: 
::slide-show
---
slides:
- image: __static__/explorer.png
  alt: "test1 - working on getting paths to CDN right..."
- image: __static__/cover.png
  alt: "test2 is it finding the png?"
---
::
--> 
If all kubescape pods are healthy, we can move on and inspect our `ApplicationProfile`, that will serve as base for our BoB. (if any of the pods are unhealthy, the `ApplicationProfile` is likely incomplete and you should not use it)

```bash
kubectl get pods -n honey -l app.kubernetes.io/instance=kubescape
```
You want the `STATUS` of all pods to be `Running`
```
laborant@dev-machine:~/honeycluster$ kubectl get pods -n honey -l app.kubernetes.io/instance=kubescape
NAME                         READY   STATUS    RESTARTS   AGE
kubescape-6685556665-5p6sh   1/1     Running   0          21m
kubevuln-5645447f88-6dc65    1/1     Running   0          21m
node-agent-5n6fr             1/1     Running   0          4m50s
node-agent-5wxzs             1/1     Running   0          4m56s
node-agent-w4c2g             1/1     Running   0          5m41s
operator-5dddf6f84-8nlpl     1/1     Running   0          21m
storage-54597f8454-nlgfh     1/1     Running   0          21m
```
Next, we ll check the configuration in order to understand  long we are expected to wait until a profile is considered ready.
The settings are in a `ConfigMap` and `CustomResourceDefinition` named RuntimeRuleAlertBinding

```sh
kubectl describe cm -n honey ks-cloud-config
kubectl describe RuntimeRuleAlertBinding all-rules-all-pods
```


So, you first wanna remember the exclusions that are set in the `rules`:
<!-- ::remark-box
---
kind: warning
---
TODO: remove the ignoreMounts/Prefixes by default, havnt found how to do that elegantly
```sh
kubectl edit RuntimeRuleAlertBinding all-rules-all-pods
```
:: -->

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
          - kube-flannel
  rules:
    - ruleName: Unexpected process launched
  #check that the following BLOCK is not in the file
    - parameters:
        ignoreMounts: true
        ignorePrefixes:
          - /proc
          - /run/secrets/kubernetes.io/serviceaccount
          - /var/run/secrets/kubernetes.io/serviceaccount
          - /tmp
  # BLOCK THAT SHOULDNT BE THERE - END
```


Couple of other important settings to be aware of that govern the anomaly detection and the
learning duration. i.e. how long we have to generate a `benign behaviour` profile. 
<!-- I chose to set these durations to be very small, as this is a demo. 
::remark-box
---
kind: warning
---
TODO: figure out if the annotation in the webapp `kubescape.io/max-sniffing-time: "2m"` takes precendence. it seems to break on k0s
and if it overrides the learningPeriod or the maxlearningPeriod or both. (the `"scanTimeout": "5m"` is related to grype and has nothing to do with the runtime stuff)
:: -->

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

in order to display this, you `can` open `k9s` by typing that in your terminal.
Then, using `vim` syntax (the one and only), inside the k9s dialogue
```bash
k9s
:helm
```
select `kubescape-operator` using the arrow-keys and press `v` for seeing the values of the `helm chart`.


```
 Context: kubernetes-admin@kubernetes 🖍            <c> … ____  __ ________          │  │        │        │ │                 │
  Cluster: kubernetes                               <e>  |    |/  /   __   \______ \ │  │        │        │ │                 │ 
  User:    kubernetes-admin                         <n>  |       /\____    /  ___/ ─ │  │        │        │ │                 │ 
  K9s Rev: v0.50.3 ⚡️ v0.50.4                        <shif|    \   \  /    /\___  \ ┐ │  │        │        │ │                 │ 
  K8s Rev: v1.32.4                                  <v>  |____|\__ \/____//____  / │ │  │        │        │ │                 │ 
  CPU:     n/a                                      <r>           \/           \/    │  │        │        │ │                 │ 
  MEM:     n/a                                                                     │ │  │        │        │ │                 │
  ┌─────────────────────────── Values(honey/kubescape) ────────────────────────────┐│ │  │        │        │ │                 │
  │ alertCRD:                                                                      ││ │  │        │        │ │                 │
  │   installDefault: true                                                         ││ │  │        │        │─│─────────────────┘
  │   scopeClustered: true                                                         ││ │  │        │        │ ┘                  
  │ capabilities:                                                                  ││ │  │      ──│────────┘                    
  │   runtimeDetection: enable                                                     ││ │  │        ┘         
  │ clusterName: honeycluster                                                      ││ │  │                 
  │ excludeNamespaces: kubescape,kube-system,kube-public,kube-node-lease,kubeconfi ││ │  │      
  │ g,gmp-system,gmp-public,honey,storm,lightening,cert-manager,openebs            ││ │  │      
  │ ksNamespace: honey                                                             ││ │ ─│──────
  │ nodeAgent:                                                                     ││ │  ┘     
  │   config:                                                                      ││ │   
  │     learningPeriod: 2m                                                         ││ │─
  │     maxLearningPeriod: 5m                                                      ││ │ 
  │     updatePeriod: 1m                                                           ││ │ 
  │   env:                                                                         ││ │
  │     - name: NodeName                                                           ││ │
  │       valueFrom:                                                               ││─│
  │         fieldRef:                                                              ││ ┘
  │           fieldPath: spec.nodeName                                          
  ││                                                                                  
```

In the beginning, we should not have any ApplicationProfiles.

```sh
kubectl get applicationprofile -A
```
after some time: likely, you ll see something like:
```json
NAMESPACE   NAME         CREATED AT
default     replicaset-webapp-85974bd68f   2025-04-16T13:58:34Z
```
Now, you may switch of the looping in the other tab and look at generated profile

```sh
export rs=$(kubectl get replicaset -n default -o jsonpath='{.items[0].metadata.name}')
kubectl describe applicationprofile replicaset-$rs
```

We want to wait until the status is completed


<!-- ::simple-task
---
:tasks: tasks
:name:  profilecomplete
---
#active
Profile is still not complete

#completed
Application profile is now complete
:: -->

If the above indicator is `green`, this means that the following event has been reached by kubescape:

```sh
kubectl logs -n honey -l app=node-agent -c node-agent | grep ended
```


```json
{"level":"info","ts":"2025-04-16T12:06:57Z","msg":"stop monitor on container - monitoring time ended","container ID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","k8s workload":"default/webapp/ping-app"}
```


We want to wait until the status is completed


Also, in the crd annotation, you will find the status completed now. 

```yaml
kubectl describe applicationprofile replicaset-webapp-xxx
...
...
Annotations:   kubescape.io/status: completed
```

Now, we must save this above file onto disk:

```sh
kubectl get applicationprofile replicaset-$rs -o yaml > app-profile-webapp.yaml
```
<!-- 
## Comparison to recording the profile when the app is already running

Just, because I found it rather insightful, let's do one more thing.

First, check the looping ping is still going on in the other tab, then come back here.

Let's delete the app


Go back to the :tab-locator-inline{text='Term 1' name='Term 1'}, where you had that ping-loop and kill it using `ctrl c`. 


-- ::simple-task
---
:tasks: tasks
:name: appprofempty
---
#active
Delete all application profiles in case you have any

#completed
Yay! All clear!
::  -->

Great job!
