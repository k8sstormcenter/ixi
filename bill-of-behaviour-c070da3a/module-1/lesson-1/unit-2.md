---
kind: unit

title: Profiling with Kubescape

name: honeycluster-up
---

Now, we are still the vendor have the `webapp` deployed on our k0s cluster. 
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


We have installed kubescape, it will help us use `eBPF/Inspector Gadget` in a hands-off manner via its nodeagent-component. So  we'll use a config that only installs the runtime-behaviour module produce an output that an end-user can directly consume, without having to deal with inspector gadget or ebpf or low-level stuff.
<!--
TODO: current config incl other stuff, and I dunno why it wants to install clamAV/grype, it shouldn't need it for this exercise, but I havent found the right combo of settings...so currently, there are components being installed, that we dont need. 

Assuming, you havnt deleted the previously cloned repo:

```
cd
cd honeycluster
```
execute the makefile to install it here on k0s:

```sh
make bob
```

While we re waiting, lets move over into the other tab :tab-locator-inline{text='Explorer' name='Explorer'} and watch what's happening on our k0s cluster.

::simple-task
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

 ::image-box
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
Well! Now, just to make sure, lets check that all kubescape pods are healthy, cause we need it to 
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


::simple-task
---
:tasks: tasks
:name:  profilecomplete
---
#active
Profile is still not complete

#completed
Application profile is now complete
::

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
