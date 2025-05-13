---
kind: unit

title: Create a Bill of Behaviour - 1 Setup the app and produce benign behaviour

name: simple-app-profile
---

Pretending we are the supplier company of the software `webapp` , which is a single container php application,
we will now create a simple BoB for this `webapp`- product.

For this first Module, we need to:  
 
* Deploy the application
* Produce traffic: execute/trigger all known behaviour (by e.g. using a load test or more old-fashioned cypress tests)
* Profile (i.e. `record` or `trace`) the benign behaviour
* Export the profile
  

## UseCase
We have two different usecases:
1) Normal anomalies 
   
   A CVE is present in the app, or it gets exploited

2) Supply Chain anomalies
 
   The artefact is not the one from the vendor , OR the vendor s supply chain got compromised, OR its a typosquatting OR something else went wrong I.e. the behaviour
   of the app has something additional in there , very often a beacon or something backdoor. Or just a cryptominer.

   Now: some of these are easy to catch:
    - cryptominers 
    - modified utilities (like using a SETUID) 
    - most sorts of exfiltration
    - droppers and loaders

for some, a SBOM is sufficient (if your chain of trust is tight). Still, the runtime behaviour could catch things in a 
orthogonal way. Like two eyes see better than one. 

   Some will be very hard to catch:
    - A pod accessing service account tokens , even if the app has zero need for one -> this is very noisy
    - the attack sleeping for very long between infection and exploitation -> it will look more like a normal attack if the correlation between the specific artefact having been deployed and the anomaly are temporarily separated . especially if its targeted (i.e. noone else sees the same thing)

## Familiarize yourself with this lab and clone the repository
Make sure, you have this lab open in Chrome. Safari doesnt work. 

Please hover over the bottom right corner of the below box, when the `Copy` symbol appears, click it and `Paste` it into the right hand `terminal` (you need to activate the playground first). In Windows, you need to right click or configure what keybindings your browser is listening to.



You now are running a development environment of `kubernetes`, in Module 3, we will run a different flavour, called `k3s`, which is a real kubernetes distribution. This is to showcase, that a vendor and a consumer will likely use different infrastructure. 

This Lab-Module 1 has also been executed on `kind`, which is often used in CI/CD, but it runs `kubernetes in docker`
allowing us to argue if running this entire BoB-generation inside CI/CD is an option. In the repo, there are `BoB` produced for a variety of kubernetes's/archs and I will be adding a discussion of their differences soon.


::remark-box
---
kind: warning
---
THIS LAB IS LIVE, live rewrites `could` be going on. 

This means, the writing on the left here can change in real time. Since you have found this lab, you likely know
Constanze, and should something happen that you have issue with, please, ping her in your usual communication channel (`icmp` may not be the right one 🤣)
::

::simple-task
---
:tasks: tasks
:name: trigger_event
---
#active
You are reading

#completed
You are now looking at this example task as finished
::
---



```bash
git clone https://github.com/k8sstormcenter/honeycluster.git
cd honeycluster
git checkout 162-write-bob-testscript-for-anyone-to-contribute-a-bob-for-the-pingapps 
make storage kubescape-bob-kind
```
::simple-task
---
:tasks: tasks
:name: git_clone_k8s
---
#active
Waiting for you to clone the repo
#completed
Congrats! 
::
---
```bash
kubectl get pods -n honey -l app.kubernetes.io/instance=kubescape
```
You want the `STATUS` of all pods to be `Running`, like so:
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
<!-- 
```git
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
git clone https://github.com/k8sstormcenter/honeycluster.git
cd honeycluster
git checkout 152-implement-bill-of-behaviour-demo-lab 
make cluster-up
make kubescape-bob-kind
``` -->

::simple-task
---
:tasks: tasks
:name: verify_kubescape_health
---
#active
Kubescape is being deployed..

#completed
Kubescape is running 
::
---


## 1 Deploy
Using a well-known `demo`** app, we deploy a ping utility called `webapp` that has

*   **a) Desired functionality:** it pings things.
*   **b) Undesired functionality:** it is vulnerable to injection (runtime is compromised).
    *   _This is to mimic a CVE in your app._
*   **c) Tampering with the artefact:** In module 2, we will additionally tamper with the artifact and make it create a backdoor (supply chain is compromised).
    *   _This is to mimic a SupplyChain corruption between vendor and you._

```sh
cd traces/kubescape-verify/attacks/webapp/
chmod +x setup.sh
./setup.sh
```



::simple-task
---
:tasks: tasks
:name: webapp
---
#active
Webapp is being deployed..

#completed
Webapp is running 
::
---

If you prefer to manually checkout your app is up:
```sh
kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

If you get `True`, proceed:


**: credit belongs entirely to the original authors


## 2 Generate Traffic of benign behaviour

<div style="background-color: #f0f8ff; border: 1px solid #ccc; padding: 10px; border-radius: 5px;">

**Benign** (*adjective*) [bi-ˈnīn] 
*   **Benignity** (*noun*) [bi-ˈnig-nə-tē]
*   **Benignly** (*adverb*) [bi-ˈnīn-lē]

**Definitions/SYNONYMS:**

1.  Of a mild type or character that does not threaten health or life. *HARMLESS*.
2.  Of a gentle disposition: *GRACIOUS*.
3.  Showing kindness and gentleness. *FAVORABLE*, *WHOLESOME*.
</div>




We assume that the full set of `benign behaviour` consists of the `webapp` performing a few pings interally to our  cluster. Thus, we simply make the app execute a few such `pings`. This is not representative for all possible things
that the `webapp` could do, but lets keep it simple, for starts.


Open a new tab :tab-locator-inline{text='new terminal' machine='dev-machine' :new=true}

Lets test the ping:

```sh
curl localhost:8080/ping.php?ip=172.16.0.2
```
if that works, let it loop 

```sh
while true; do curl localhost:8080/ping.php?ip=172.16.0.2; sleep 10; done
```
Do not kill the looping.
Please, switch back to the original :tab-locator-inline{text='dev-machine' name='dev-machine'} tab, and you are ✅
::remark-box
---
kind: warning
---


__WIP__: We understand that this `webapp` is extremely simplistic and in Module 4 will show how we 
would approach multi-container pods, such as when `sidecars` are injected.

There we'll discuss how those deployments can be handled and if everything is `additive`

(Thanks Ben for pointing this out)
::


## References

- [Enhance SBOMs with runtime security context by using Datadog Software Composition Analysis](https://www.datadoghq.com/blog/enhance-sboms-application-vulnerability-management/)
- 


## Glossary


- **Software Bill of Behaviour (SBOB) or (BoB)**  
  A Software Bill of Behaviors (SBoB) is an emerging concept aimed at capturing and documenting the runtime behavior of software components to enhance system security and threat detection.







