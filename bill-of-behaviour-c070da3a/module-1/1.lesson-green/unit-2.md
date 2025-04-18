---
kind: unit

title: Profiling with Kubescape

name: honeycluster-up
---

Now, we are still the vendor have the `webapp` deployed on our k0s cluster. 
We are producing `benign` traffic that triggers all known behaviour of our `webapp`

::remark-box
---
kind: warning
---
__IRL__: the vendor needs to ensure that all application and network behaviour during a normal productive usecase
are being triggered. Usually, this would be a combo between integration, load and behaviour-driven tests. Maybe UX test
or traffic replay.

We got the concrete question about Jupyter, and there C put a lot of thinking in 2021 around JupyterHub-deployments for several unis: mimicked what the students from different faculties would do: we essentially injected python exams and homeworks into the pods and executed them headlessly. Later did the same with fortran-hpc code and 3D-vizualization tools - headless in jupyterhub-> if you know at least the use-case (HPC vs student-homework in this case) and how your platform integrates with storage/shares -> you can trigger all syscalls. you can `not` trigger all network traffic. 
ended up going the opposite way of explicitely monitoring for signatures of deviant behaviour, especially for the fileaccess. Here a more concrete threat-modelling and life-recording at the client was more useful, given the degree of heterogeneity.

I think, a BoB can be useful as a starting point to detect if there are key-loggers or C2 embedded somewhere... Thats an interesting test... if someone wants to set it up
::


Let's install kubescape, it will help us use `Inspector Gadget` in a hands-off manner and produce an output, we can direclty consume:

Assuming, you havnt deleted the previously cloned repo:

```
cd
cd honeycluster
```
execute the makefile to install it here on k0s:

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
Congrats! (WIP: this check is currently meaningless)
::

You can watch the pods becoming blue and select those items you d like to `watch` with the `eye` icon.

::image-box
---
:src: __stаtic__/explorer.png
:alt: 'Watching pods in explorer tab'
---
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
::remark-box
---
kind: warning
---
TODO: remove the ignoreMounts/Prefixes by default, havnt found how to do that elegantly
::

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
::remark-box
---
kind: warning
---
TODO: figure out if the annotation in the webapp `kubescape.io/max-sniffing-time: "2m"` takes precendence
and if it overrides the learningPeriod or the maxlearningPeriod or both.
::

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
and likely, you ll see something like:
```json
NAMESPACE   NAME         CREATED AT
default     pod-webapp   2025-04-16T13:58:34Z
```
Now, you may switch of the looping in the other tab and look at generated profile
```sh
kubectl describe applicationprofile pod-webapp 
```

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

Great job!
