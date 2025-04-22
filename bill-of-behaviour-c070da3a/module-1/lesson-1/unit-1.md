---
kind: unit

title: Create a Bill of Behaviour - Setup the app

name: simple-app-profile
---

Pretending we are the supplier company of the software `webapp` , which is a single container php application,
we will now create a simple BoB for this `webapp`- product.

For this, we need to:  
 
* Deploy the application
* Produce traffic: execute/trigger all known behaviour (by e.g. using a load test or more old-fashioned cypress tests)
* Profile the benign behaviour
* Export the profile
  


## 0 Clone repository for this lab 
Make sure, you have this lab open in chrome. Safari doesnt work. 

Please hover over the bottom right corner of the below box, when the `Copy` symbol appears, click it and `Paste` it into the right hand `terminal` (you need to activate the playground first). In Windows, you need to right click or configure what keybindings your browser is listening to.

You now are running a slim flavour of `kubernetes` called k0s, in Module 3, we will run a different flavour, called k3s. This is to showcase, that a vendor and a consumer will likely use different infrastructure.
To safe you the config, the following repo contains settings that  WIP: 🤣 __will__ work 😂 

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

::remark-box
---
kind: warning
---
Sequence: repeat the profiling , with kubescape already deployed to assure the container startup is captured --
hmmm doesnt seem to make a difference. Need to repeat this on kind and gke to check -- I m not believing the current profile to be correct
```sh
make bob
```
...wait for all 4 pods to be there esp nodeagent
::


## 1 Deploy
Using one of the `kubescape-demo`** apps, we deploy a ping utility called `webapp` that has

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

If you prefer to manually checkout your app is up:
```sh
kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
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

<div style="background-color: #f0f8ff; border: 1px solid #ccc; padding: 10px; border-radius: 5px;">

**Benign** (*adjective*) [bi-ˈnīn] 
*   **Benignity** (*noun*) [bi-ˈnig-nə-tē]
*   **Benignly** (*adverb*) [bi-ˈnīn-lē]

**Definitions/SYNONYMS:**

1.  Of a mild type or character that does not threaten health or life. *HARMLESS*.
2.  Of a gentle disposition: *GRACIOUS*.
3.  Showing kindness and gentleness. *FAVORABLE*, *WHOLESOME*.
</div>




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
if that works, let it loop 

```sh
while true; do curl 172.16.0.2:$port/ping.php?ip=172.16.0.2; sleep 10; done
```
Do not kill the looping.
Please, switch back to the original :tab-locator-inline{text='k0s-01' name='k0s-01'} tab, and you are ✅
::remark-box
---
kind: warning
---


__Optional__: you could expose this app on port `58080` and use a new brower tab (see setup.sh)
```
#sudo socat TCP-LISTEN:58080,bind=172.16.0.2,reuseaddr,fork TCP:127.0.0.1:58080&
```
::

<!-- 

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



<!-- [Debug: restart the nodeagent]

```sh
kubectl rollout restart ds -n honey node-agent 
``` -->
<!-- 
## Test
So, we are done here, but we could - just for kicks - verify that kubescape is now watching for anything that was not previously recorded as `benign` and execute a simple injection like so:

in Tab 1 tail the logs again
```sh
kubectl logs -n honey -l app=node-agent -f -c node-agent
```
and in Tab 2, let's do something malicious

```sh
curl 172.16.0.2:31158/ping.php?ip=172.16.0.2,ls
```


**: credit belongs entirely to the original authors

```yaml
Name:         pod-ping-app
Namespace:    default
Labels:       kubescape.io/workload-api-version=v1
              kubescape.io/workload-kind=Pod
              kubescape.io/workload-name=ping-app
              kubescape.io/workload-namespace=default
              kubescape.io/workload-resource-version=1966
Annotations:  kubescape.io/completion: partial
              kubescape.io/instance-id: apiVersion-v1/namespace-default/kind-Pod/name-ping-app
              kubescape.io/resource-size: 9
              kubescape.io/status: completed
              kubescape.io/wlid: wlid://cluster-honeycluster/namespace-default/pod-ping-app
API Version:  spdx.softwarecomposition.kubescape.io/v1beta1
Kind:         ApplicationProfile
Metadata:
  Creation Timestamp:  2025-04-15T19:47:13Z
  Resource Version:    4
  UID:                 08396cda-4519-48ce-9c7c-9d530a19123a
Spec:
  Architectures:
    amd64
  Containers:
    Capabilities:
      NET_RAW
      SETUID
    Endpoints:  <nil>
    Execs:
      Args:
        /bin/sh
        -c
        ping -c 4 172.16.0.2
      Path:  /bin/sh
      Args:
        /bin/ping
        -c
        4
        172.16.0.2
      Path:     /bin/ping
    Image ID:   docker.io/amitschendel/ping-app@sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d
    Image Tag:  docker.io/amitschendel/ping-app:latest
    Name:       ping-app
    Opens:
      Flags:
        O_CLOEXEC
        O_RDONLY
      Path:  /usr/lib/x86_64-linux-gnu/libunistring.so.2.1.0
      Flags:
        O_RDONLY
      Path:  /var/www/html/ping.php
      Flags:
        O_CLOEXEC
        O_RDONLY
      Path:  /etc/ld.so.cache
      Flags:
        O_CLOEXEC
        O_RDONLY
      Path:  /lib/x86_64-linux-gnu/libc-2.31.so
      Flags:
        O_CLOEXEC
        O_RDONLY
      Path:  /lib/x86_64-linux-gnu/libcap.so.2.44
      Flags:
        O_CLOEXEC
        O_RDONLY
      Path:  /usr/lib/x86_64-linux-gnu/libidn2.so.0.3.7
      Flags:
        O_CLOEXEC
        O_RDONLY
      Path:  /lib/x86_64-linux-gnu/libresolv-2.31.so
    Rule Policies:
      R0001:
      R0002:
      R0003:
      R0004:
      R0005:
      R0006:
      R0007:
      R0008:
      R0009:
      R0010:
      R0011:
      R1000:
      R1001:
      R1002:
      R1003:
      R1004:
      R1005:
      R1006:
      R1007:
      R1008:
      R1009:
      R1010:
      R1011:
      R1012:
      R1015:
      R1030:
    Seccomp Profile:
      Spec:
        Default Action:  
    Syscalls:
      accept4
      access
      arch_prctl
      brk
      capget
      capset
      chdir
      clone
      close
      connect
      dup2
      execve
      exit_group
      fcntl
      fstat
      getcwd
      getegid
      geteuid
      getgid
      getpid
      getppid
      getrandom
      getsockname
      getsockopt
      getuid
      ioctl
      lstat
      mmap
      mprotect
      munmap
      openat
      pipe2
      poll
      prctl
      prlimit64
      read
      recvmsg
      rt_sigaction
      rt_sigprocmask
      rt_sigreturn
      select
      sendto
      setitimer
      setsockopt
      setuid
      shutdown
      socket
      stat
      times
      vfork
      wait4
      write
      writev
Status:
Events:  <none>
``` --> -->