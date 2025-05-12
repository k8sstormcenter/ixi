---
kind: unit

title: Setup the app

name: debug-kubescape-1
---

Pretending we are the supplier company of the software `webapp` , which is a single container php application,
we will now create a simple BoB for this `webapp`- product.

For this, we need to:  
 
* Deploy the application
* Produce traffic: execute/trigger all known behaviour (by e.g. using a load test or more old-fashioned cypress tests)
* Profile the benign behaviour
* Export the profile

::simple-task
---
:tasks: tasks
:name: trigger_event
---
#active
You are reading

#completed
You are now looking at this example task as finished in Module 4 , means it loaded correctly
::
---


## 0 Clone repo
Make sure, you have this lab open in chrome. Safari doesnt work. 

Please hover over the bottom right corner of the below box, when the `Copy` symbol appears, click it and `Paste` it into the right hand `terminal` (you need to activate the playground first). In Windows, you need to right click or configure what keybindings your browser is listening to.

```git
git clone https://github.com/k8sstormcenter/honeycluster.git
cd honeycluster
make bob
```
::simple-task
---
:tasks: tasks
:name: git_clone_1
---
#active
Waiting for you to clone the repo


#completed
Congrats! 
::

## 1 Deploy

Using one of the `kubescape-demo`** apps, we deploy a ping utility called `webapp` that has

*   **a) Desired functionality:** it pings things.
*   **b) Undesired functionality:** it is vulnerable to injection (runtime is compromised).
    *   _This is to mimic a CVE in your app._
*   **c) Tampering with the artefact:** In module 2, we will additionally tamper with the artifact and make it create a backdoor (supply chain is compromised).
    *   _This is to mimic a SupplyChain corruption between vendor and you._



```sh
cd traces/kubescape-verify/attacks/webapp_debug_k0s/
chmod +x setup.sh
./setup.sh
```



::simple-task
---
:tasks: tasks
:name: webapp_1
---
#active
Webapp is being deployed..

#completed
Webapp is running (WIP this check is always green)
::


```sh
kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

If you get `True`, proceed:


**: credit belongs entirely to the original authors


## 2 Generate Traffic of benign behaviour
Optional: you could expose this app on port `58080` and use a new brower tab (see setup.sh)


We assume that the full set of `benign behaviour` consists of the `webapp` performing a few pings interally to our `k0s` cluster. Thus, we simply make the app execute a few such pings via the `nodeport`, which is conviently exposed on our k0s-node, already:


Open a new tab :tab-locator-inline{text='another terminal' :new=true}

First, find the nodeport IP
```sh
export port=$(kubectl describe svc/webapp | grep NodePort | awk '{print $3}' | cut -d '/' -f1)
echo "NodePort is: $port"
```
now, test the ping:

```sh
curl 172.16.0.2:$port/ping.php?ip=172.16.0.2
```
if that works, lets loop it for a bit.

```sh
while true; do curl 172.16.0.2:$port/ping.php?ip=172.16.0.2; sleep 10; done
```

