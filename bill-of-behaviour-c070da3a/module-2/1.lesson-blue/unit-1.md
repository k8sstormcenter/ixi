---
kind: unit

title: Building and Tagging the OCI artefact

name: oci-build-tag
---

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
docker buildx build --sbom=true -t registry.iximiuz.com/test:latest --push .
```

<!-- ```
sudo ctr image push --user iximiuzlabs:rules! registry.iximiuz.com/test:latest
``` -->

Faucibus commodo massa rhoncus, volutpat. Dignissim sed eget risus enim. Mattis mauris semper sed amet vitae sed turpis id. Id dolor praesent donec est. Odio penatibus risus viverra tellus varius sit neque erat velit. Faucibus commodo massa rhoncus, volutpat. Dignissim sed eget risus enim. Mattis mauris semper sed amet vitae sed turpis id.
