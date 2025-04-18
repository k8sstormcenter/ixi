---
kind: unit

title: Setup the app

name: simple-app-profile
---

Pretending we are the supplier company of the software `webapp` , which is a single container php application,
we will now create a simple BoB for our product.

For this, we need to:  (TODO: make this tableofcontnets)
 
* 1 deploy it
* 2 execute/trigger all known behaviour (by e.g. using a load test or more old-fashioned cypress tests)
* 3 profile the benign behaviour
* 4 export the profile

## 0 Clone repo
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

## 1 Deploy
Using one of the `kubescape-demo`** apps, we deploy a ping utility called `webapp` that has

a) desired functionality: it pings things  

b) undesired funtionality: it is vulnerable to injection

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
Webapp is running (WIP this check is always green)
::


```sh
kubectl get pods -l app=ping-app -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

If you get `True`, proceed:


**: credit belongs entirely to the original authors

<!-- ```sh
kubectl logs -n honey -l app=node-agent -f -c node-agent
```
or debug:
```sh
kubectl logs -n honey node-agent-<TAB COMPLETE>
```

```
kubectl create ns nginx
kubectl create deployment --image=nginx nginx -n nginx
``` -->

## 2 Generate Traffic of benign behaviour
Optional: you could expose this app on port `58080` and use a new brower tab (see setup.sh)


We assume that the full set of `benign behaviour` consists of the `webapp` performing a few pings interally to our `k0s` cluster. Thus, we simply make the app execute a few such pings via the `nodeport`, which is conviently exposed on our k0s-node, already:


First find the nodeport IP
```sh
kubectl describe svc/ping-app |grep NodePort
```

now, export this port to the local shell
```sh
export port=<NodePort>
```

```sh
curl 172.16.0.2:$port/ping.php?ip=172.16.0.2
```
if that works, lets loop it for a bit.
Open a new tab :tab-locator-inline{text='another terminal' :new=true}
```sh
while true; do curl 172.16.0.2:$port/ping.php?ip=172.16.0.2; sleep 10; done
```

