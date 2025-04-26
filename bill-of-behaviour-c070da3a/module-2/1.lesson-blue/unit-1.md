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

dear co-autor P: is C correct in assuming you wanted to build this part?
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
Sketch: - be'ware the stream of consciousness writing style


Highlevel:
```yaml
Executables: Paths and arguments of executables that are expected to run.
Network Connections: Expected network connections (IP addresses, DNS names, ports, protocols).
File Access: Expected file access patterns (paths, read/write). 
System Calls: Expected system calls.
Capabilities: Expected Linux capabilities. #TBC differs accross containerruntimes -> TODO recapture the profile, check the image sha
Image information: Image ID, Image Tag.
```

Detailed concrete example: 

TODO: This must be produced this for each `architecture`,  file_access directly depends on `arch`, but depending how exotic the `arch` more may be different. `execs` depend on the flavour kubernetes
```json
{
  "version": "1.0",
  "image_id": "docker.io/amitschendel/ping-app@sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d",
  "image_tag": "docker.io/amitschendel/ping-app:latest",
  "architectures":  "amd64",
  "executables": [
    {
      "path": "/bin/ping",
      "args": ["-c", "4", "placeholder maybe CIDR regex"]
    },
    {
      "path": "/bin/sh",
      "args": ["-c", "ping placeholder"] TODO: test or dig through the code if a regex works here, else we need to remove the args, or ask vendors to remove such non-generic pieces themselves. Probably good to let vendors commit to as much as possible
    }
  ],
  "file_access": [
    {
      "path": "/var/www/html/ping.php",
      "flags": ["O_RDONLY"]
    },
    {
      "path": "/lib/x86_64-linux-gnu/libc-2.31.so", TODO: think if there are cases when dynamic linking would be using something non-deterministic , thinking how podman or singularity could be doing things differently , are those relevant?
      "flags": ["O_CLOEXEC", "O_RDONLY"]
    }
  ],
  "system_calls": [
    "accept4",
    "access",
    "arch_prctl",
    "brk",
    "capget",
    "capset",
    "chdir",
    "clone",
    "close"
  ],
  "capabilities": [
    "NET_RAW",
    "SETUID"
  ],
  "endpoints": [
    {
      "direction": "inbound",
      "endpoint": ":<PORT>/ping.php",
      "headers": {
        "Host": "probably wont be generic"
      },
      "internal": false,
      "methods": [
        "GET"
      ]
    },
    {
      "direction": "outbound",
      "endpoint": "k8sstormcenter.com:443",
      "protocol": "tcp",
      "internal": false,
      "methods": [
        "LETS RECORD AN EXAMPLE"
      ]
    },
    {
      "direction": "outbound",
      "endpoint": "k8sstormcenter.com",
      "protocol": "udp",
      "internal": false,
      "methods": [
        "DNS_QUERY"
      ],
      "dns": {
        "query_type": "A",
        "query_name": "k8sstormcenter.com",
        "response": {
          "answer": [
            {
              "name": "k8sstormcenter.com",
              "type": "A",
              "ttl": 300,
              "data": "192.168.1.100" # DO WE WANT TO commit to the answer, or leave it as optional if a vendor is super sure they have static IPs. the DNS part could be very valuable in detecting malicious behaviour, probably good to have it as OPTIONAL
            }
          ]
        }
      }
    }
  ]
}
```

## 2) Building the artefact with the BoB included


Need to reclone, cause this is a new environment with docker/buildx , not k0s

```git
git clone https://github.com/k8sstormcenter/honeycluster.git
cd honeycluster
git checkout 152-implement-bill-of-behaviour-demo-lab 
cd traces/kubescape-verify/attacks/webapp/
```
Sketch of commands

```sh
docker buildx create --use --name=buildkit-container --driver=docker-container
docker buildx build --bob=true -t registry.iximiuz.com/webapp:latest --push .
```


<!-- 
So, we have our `ApplicationProfile` from the last section;

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
```



Lets test building our artefact:

```git
git clone https://github.com/k8sstormcenter/honeycluster.git
cd honeycluster
git checkout 152-implement-bill-of-behaviour-demo-lab 
cd traces/kubescape-verify/attacks/webapp/
```

```sh
docker buildx create --use --name=buildkit-container --driver=docker-container
docker buildx build --bob=true -t registry.iximiuz.com/webapp:latest --push .
```

 -->
