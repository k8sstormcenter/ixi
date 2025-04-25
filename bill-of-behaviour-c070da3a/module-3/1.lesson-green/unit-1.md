---
kind: unit

title: Consume the app on client cluster

name: consume-app-install
---

Pretending we are now the consumer/user of `webapp` , we have our own infrastructure.
This consumer uses k3s, which is another slim kubernetes flavour from a different vendor than k0s.

We, ll cover the following
 
* Get to know our k3s installation
* Deploy kubescape in a slightly different config to give us anomaly detection
* Follow the 2-step installation process
* Watch it for the two types of anomalies
  

## 0 Clone repo
Again, lets clone the same repo, this is a fresh playground
```git
git clone https://github.com/k8sstormcenter/honeycluster.git
cd honeycluster
git checkout 152-implement-bill-of-behaviour-demo-lab 
```
::simple-task
---
:tasks: tasks
:name: git_clone
---
#active
Waiting for you to clone the repo


#completed
Congrats! 
::

## 1 Install kubescape and wait until it's up and running

```sh
make kubescape-bob-kind
```
```bash
kubectl get pods -n honey -l app.kubernetes.io/instance=kubescape
```
You want the `STATUS` of all pods to be `Running`, like so:
```
laborant@dev-machine:webapp_t$ kubectl get pods -n honey -l app.kubernetes.io/instance=kubescape
NAME                                READY   STATUS    RESTARTS   AGE
grype-offline-db-579c6cbc47-rvgqk   1/1     Running   0          20m
node-agent-b4qmg                    2/2     Running   0          20m
node-agent-tgs8f                    2/2     Running   0          20m
node-agent-vslk6                    2/2     Running   0          20m
operator-559b868885-kr8dt           1/1     Running   0          20m
storage-79d6fd9785-gdpx2            1/1     Running   0          20m
```


Check out the Explorer tab :tab-locator-inline{text='Explorer' name='Explorer'}, then navigate to `All Objects`
and expand, hover and toggle the 👁️-Icon on `spdx.softwarecomposition.kubescape.io/v1beta1` -> `ApplicationProfile` , then navigate to
the bottom `Watched Objects` . You are now watching for these Application Profiles and no longer need to filter

## 2 pull down artefact (not yet implemented)
WIP: 

```sh
some mystical command like ctr pull
```

We will simply use our images `k8sstormcenter/webapp:latest` and `k8sstormcenter/webapp-t:latest`
which are multi-arch reproductions of `docker.io/amitschendel/ping-app:latest` with `-t` meaning it was tampered.
Their Dockerfiles (and github-workflows)are

https://github.com/k8sstormcenter/honeycluster/blob/152-implement-bill-of-behaviour-demo-lab/.github/workflows/publish-image-kubescape-webapp.yml

## 3 deploy artefact (first without tampering)

Ok, now we pretend to just install that `webapp` image , that we as customer think is the correct one.

So, this (will be) the exact same artefact as in Module-1, just on a different tech stack now:
```sh
cd traces/kubescape-verify/attacks/webapp/
chmod +x setup.sh
./setup.sh
```

## 4 Use the artefact in a functional, benign way
So, we again, do the almost same things:

This app was made for pinging, so we ping

Open a new tab :tab-locator-inline{text='new terminal' machine='dev-machine' :new=true}
Let's ping:

```sh
curl localhost:8080/ping.php?ip=172.16.0.2
```
if that works, let it loop 

```sh
while true; do curl localhost:8080/ping.php?ip=172.16.0.2; sleep 10; done
```
Do not kill the looping.
Please, switch back to the original :tab-locator-inline{text='dev-machine' name='dev-machine'} tab, and proceed



## 5 Wait for kubescape to settle

TODO: replace with more production like method.

The `garbage out, patch in` method :

We ll wait until we have an application profile again and we ll throw it away.


Lets check the configuration in order to understand if the setup is any different from Module 1:
```sh
kubectl describe cm -n honey ks-cloud-config
kubectl describe RuntimeRuleAlertBinding all-rules-all-pods
```

```sh
kubectl get applicationProfile -A
```
```
laborant@dev-machine:webapp_t$ kubectl get applicationProfile -A
NAMESPACE   NAME                           CREATED AT
default     replicaset-webapp-75c688bfc4   2025-04-25T12:38:28Z
```

```sh
export rs=$(kubectl get replicaset -n default -o jsonpath='{.items[0].metadata.name}')
kubectl describe applicationprofile replicaset-$rs
```
```sh
kubectl get applicationProfile replicaset-$rs  -o yaml > ~/originalappprofile.yaml
```

now edit that profile (so it keeps it name), but use the content of the one from Module 1!!!
```sh   
echo $rs
envsubst < /home/laborant/honeycluster/traces/kubescape-verify/attacks/webapp/bob_applicationprofile.yaml > /home/laborant/honeycluster/traces/kubescape-verify/attacks/webapp/bob.yaml
```

`patch` the ping-profile:

```sh
kubectl apply -f /home/laborant/honeycluster/traces/kubescape-verify/attacks/webapp/bob.yaml
```
Make sure you didnt wake ~~the dragon~~ kubescape
```
kubectl logs -n honey -l app=node-agent
```
there should be no additional logs, only the stop of the above profile, similar to:

```json
{"level":"info","ts":"2025-04-25T16:25:13Z","msg":"RBCache - ruleBinding added/modified","name":"/all-rules-all-pods"}
{"level":"info","ts":"2025-04-25T17:05:15Z","msg":"start monitor on container","container ID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8","k8s workload":"default/webapp-8b697d7f9-h9mx4/ping-app","ContainerImageDigest":"sha256:31eb54dc4f5e3537a807e1a5cbc2de9d6c0a5f4e423a5137627e664748f03d7f","ContainerImageName":"ghcr.io/k8sstormcenter/webapp:latest"}
{"level":"info","ts":"2025-04-25T17:10:15Z","msg":"stop monitor on container - monitoring time ended","container ID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8","k8s workload":"default/webapp-8b697d7f9-h9mx4/ping-app"}
```


Quick Summary:

We as customer deployed `webapp`, we didnt check its signature, we recorded a profile and threw away that profile by overwriting it with the profile from Module 1, aka `BoB`.
We did this to trick kubescape into believing, it has recorded the supplied `BoB`  (the metadata of the profile are correct). 

## 6 watch how k3s is different from k8s


