---
kind: unit

title: Create the Bill Of Behaviour - Hello Bob

name: debug-3
---

Go back to the tab, where you had that ping-loop and kill it using `ctrl c`. 

Lets check the profile that recorded this `benign behaviour`
```sh
kubectl describe applicationprofile pod-webapp 
```

``` yaml
Spec:
  Architectures:
    amd64
  Containers:
    Capabilities:
      NET_RAW
      SETUID
    Endpoints:
      Direction:  inbound
      Endpoint:   :32132/ping.php
      Headers:
        Host:
          172.16.0.2:32132
      Internal:  false
      Methods:
        GET
    Execs:
      Args:
        /bin/ping
        -c
        4
        172.16.0.2
      Path:  /bin/ping
      Args:
        /bin/sh
        -c
        ping -c 4 172.16.0.2
      Path:                  /bin/sh
    Identified Call Stacks:  <nil>
    Image ID:                docker.io/amitschendel/ping-app@sha256:99fe0f297bbaeca...
    Image Tag:               docker.io/amitschendel/ping-app:latest
    Name:                    ping-app
    Opens:
      Flags:
        O_RDONLY
      Path:  /var/www/html/ping.php
      Flags:
        O_CLOEXEC
        O_RDONLY
      Path:  /lib/x86_64-linux-gnu/libc-2.31.so
      Flags:
        O_CLOEXEC
        O_RDONLY
      ...
    Rule Policies:  <nil>
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
      ...
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
Also, in the crd annotation, you will find the status completed now. The completion is `partial`, which 
we may ignore here (accrd to upstream documentation it means that the app was already started when we were profiling it)

```yaml
kubectl describe applicationprofile pod-webapp 
...
...
Annotations:  kubescape.io/completion: partial
              kubescape.io/instance-id: apiVersion-v1/namespace-default/kind-Pod/name-webapp
              kubescape.io/resource-size: 9
              kubescape.io/status: completed
```

And so far on k0s, you can t get the `kubescape.io/completion: complete` , at least I havnt found how.

