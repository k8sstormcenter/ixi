---
kind: unit

title: Building and Tagging the OCI artefact

name: oci-build-tag
---

### Vendor publishes artefact with BoB

* extract a json conformant with predicate format from the ebpf-recording 
* if this is a Container: pretend use docker `--bob=true` build ...
* if this is another type of artefact like helm: have a means to append the predicate

No well-established API should change, else people are not going to use it.

::simple-task
---
:tasks: tasks
:name: trigger_event
---
#active
You are reading

#completed
You are now looking at this example task as finished in Module 2, means it loaded correctly
::
---


## 1) Predicate Format



Highlevel:
```yaml
Header: 
Executables: Paths and arguments of executables that are expected to run.
Network Connections: Expected network connections (IP addresses, DNS names, ports, protocols).
File Access: Expected file access patterns (paths, read/write). 
System Calls: Expected system calls.
Capabilities: Expected Linux capabilities. 
Image information: Image ID, Image Tag.
```

Header (in the assumption we can use kubescape directly):
```yaml
apiVersion: spdx.softwarecomposition.kubescape.io/v1beta1
kind: ApplicationProfile
metadata:
  annotations:
    kubescape.io/completion: complete
    kubescape.io/instance-id: apiVersion-apps/v1/namespace-$values.namespace/kind-$values.camelinstancekind/name-$values.name-$values.templatehash
    kubescape.io/status: completed
    kubescape.io/wlid: wlid://cluster-$values.clustername/namespace-$values.namespace/$values.workloadkind-$values.name
  labels:
    kubescape.io/workload-api-group: apps
    kubescape.io/workload-api-version: v1
    kubescape.io/workload-kind: $values.camelworkloadkind
    kubescape.io/workload-name: $values.name
    kubescape.io/workload-namespace: $values.namespace
  name: $values.instancekind-$values.name-$values.templatehash
  namespace: $values.namespace
  resourceVersion: "1"
```
Ideal Header
```
apiVersion: 
kind: BillOfBehavior
metadata:
  annotations:
  labels:
  name:
  namespace:
```



## 2) Building the BoB including a test


Lets take our ApplicationProfile and create a very simply bob



```git
git clone https://github.com/k8sstormcenter/honeycluster.git
cd honeycluster
git checkout 162-write-bob-testscript-for-anyone-to-contribute-a-bob-for-the-pingapps
cd traces/kubescape-verify/attacks/bob
ls
cat bob.values
```

First, as a vendor, I need to choose what will be substitutable by a customer and what tests I can give to the customer.

The content of the `bob` is:
- bob.yaml
- bob.values
- bob.test

### Here and Back Again
A bob's tale:


```bash
sudo apt install python3-yaml  
```
```bash
python3 bob.py 
```

Well, rather minimalistic, but a sketch how to extract the `values` and substitute them back in:

```yaml 
==> bob_generated.values <==
namespace=default
name=webapp
clustername=honeycluster
templatehash=d87cdd796
workloadkind=deployment
camelworkloadkind=Deployment
instancekind=replicaset
camelinstancekind=ApplicationProfile

==> bob_generated.yaml <==
apiVersion: spdx.softwarecomposition.kubescape.io/v1beta1
kind: ApplicationProfile
metadata:
  annotations:
    kubescape.io/completion: complete
    kubescape.io/instance-id: apiVersion-apps/v1/namespace-$values.namespace/kind-$values.camelinstancekind/name-$values.name-$values.templatehash
    kubescape.io/resource-size: '245'
    kubescape.io/status: completed
    kubescape.io/wlid: wlid://cluster-$values.clustername/namespace-$values.namespace/$values.workloadkind-$values.name
  creationTimestamp: '2025-05-12T12:45:42Z'

==> processed_bob_generated.yaml <==
apiVersion: spdx.softwarecomposition.kubescape.io/v1beta1
kind: ApplicationProfile
metadata:
  annotations:
    kubescape.io/completion: complete
    kubescape.io/instance-id: apiVersion-apps/v1/namespace-default/kind-ApplicationProfile/name-webapp-d87cdd796
    kubescape.io/resource-size: '245'
    kubescape.io/status: completed
    kubescape.io/wlid: wlid://cluster-honeycluster/namespace-default/deployment-webapp
  creationTimestamp: '2025-05-12T12:45:42Z'
```




Now, we have simply substituted out the CRD header so we can `transfer` it .
I suggest, we have `variables` and `defaults` with a well-defined precedence.

Ideally, on the other side (the customer side), we will have a composable way to unionize the runtimeAspects (making 
multiple BoBs `additive` ). So, I suspect the `bobctl` will need to be able to merge bob.yaml files.


Later work: we need to create functions to replace sections. I see mostly networking being cumbersome.
For example; for the following scenario:
```yaml
    endpoints:
    - direction: inbound
      endpoint: :8080/ping.php
      headers:
        Host:
        - localhost:8080
      internal: false
      methods:
      - GET
```
it is not currently clear to me, if this fails open or fails closed. Given, that port-forwarding/api-gw/ingress will be vastly
different, the `endpoint` section should maybe be discovered. But, again, be added in. It is unlikely we can pre-determine it.

