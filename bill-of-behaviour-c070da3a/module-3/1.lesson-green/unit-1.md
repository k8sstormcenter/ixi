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
* Pull down the artefact `webapp` and deploy it
* Verify some things
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

## 1 setup kubescape

```sh
make kubescape
```


## 2 pull down artefact

```sh
some mystical command like ctr pull
```


## 3 deploy artefact

WIP: currently testing the tampered artefact deployment automation

Hang on: step 1 is deploying the application profile -> add this TODO
```sh
cd traces/kubescape-verify/attacks/webapp_t/
chmod +x setup.sh
./setup.sh
```



the looping as before, but this time the signature should be different

```sh
export port=$(kubectl describe svc/webapp | grep NodePort | awk '{print $3}' | cut -d '/' -f1)
echo "NodePort is: $port"
while true; do curl 172.16.0.2:$port/ping.php?ip=172.16.0.2; sleep 10; done
```
## 4 apply the 