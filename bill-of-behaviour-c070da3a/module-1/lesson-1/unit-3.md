---
kind: unit

title: Create the Bill Of Behaviour - Hello Bob

name: hello-bob
---



Lets look in more detail at the profile that recorded this `benign behaviour` , yours should be `different`
```sh
cat app-profile-webapp.yaml 
```


The following one was recorded on a k0s (you are on a different cluster), so yours should be a lot longer (and I mean `a lot`).

TODO:

Discuss each `block` of this profile here at length.


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


## Is this relevant, does this translate across different cluster types?

Glad you asked :)

It does ... somehwat . Before we look at various sidecars and multi-container-pods. Lets stay with this simply ping `webapp` that does very little, and compare its profiles across various clusters and archs:

::tabbed
---
tabs:
  - name: 
    title: Tab 1
  - name: tab2
    title: Tab 2
---
#tab1
...markdown...

#tab2
...markdown...
::




## CUSTOMER SIDE SKETCH  (this will be moved into the Module 3)

@EarlyReviewers: now in Module 2, we need to implement the publication of the BoB into a `predicate`, attach it to container/artefact in OCI compliant way, sign, push,  ....
on the other side, a client will do almost the exact same thing in reverse: pull, verify signature, extract the BoB, feed it to kubernetes.



So, just for the storyline: pretending we are now the `customer` and in Module 2, we verified the signature, deployed the app. 
We now verify that kubescape is now watching for anything that was not previously recorded as `benign` .

Again, we have two different usecases:
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


TODO: C wants to implement specifically an exfiltration usecase: where the app is not just doing a ping, but sending telemetry to the maintainers for debugging purposes. Can we estimate the increase in detection rates if we include known telemetry network endpoints into the BoB? (Task for C)

### 1) Normal anomalies: A malicious runtime behaviour by executing a simple injection like so:

in Tab 1 tail the logs again
```sh
kubectl logs -n honey -l app=node-agent -f -c node-agent
```
and in Tab 2, let's do something malicious

```sh
curl 172.16.0.2:$port/ping.php?ip=172.16.0.2,ls
```
In the other tab, you should now see several unexpected things:
```json
{"BaseRuntimeMetadata":{"alertName":"Unexpected file access","arguments":{"flags":["O_RDONLY","O_CLOEXEC"],"path":"/lib/x86_64-linux-gnu/libnss_files-2.31.so"},"infectedPID":22169,"severity":1,"timestamp":"2025-04-16T12:15:55.810283302Z","trace":{}},"CloudMetadata":null,"RuleID":"R0002","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"image":"docker.io/amitschendel/ping-app:latest","imageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d","namespace":"default","containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","podName":"ping-app","podNamespace":"default","workloadName":"ping-app","workloadNamespace":"default","workloadKind":"Pod"},"RuntimeProcessDetails":{"processTree":{"pid":2709,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2486,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":2734,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":22168,"cmdline":"/bin/sh -c ping -c 4 172.16.0.2,ls","comm":"sh","ppid":2734,"pcomm":"apache2","hardlink":"/bin/dash","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/dash","children":[{"pid":22169,"cmdline":"/bin/ping -c 4 172.16.0.2,ls","comm":"ping","ppid":22168,"pcomm":"sh","hardlink":"/bin/ping","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/ping"}]}]}]},"containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924"},"event":{"runtime":{"runtimeName":"containerd","containerId":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","containerName":"ping-app","containerImageName":"docker.io/amitschendel/ping-app:latest","containerImageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d"},"k8s":{"namespace":"default","podName":"ping-app","podLabels":{"app":"ping-app","kubescape.io/max-sniffing-time":"5m"},"containerName":"ping-app","owner":{}},"timestamp":1744805755810283302,"type":"normal"},"level":"error","message":"Unexpected file access: /lib/x86_64-linux-gnu/libnss_files-2.31.so with flags O_RDONLY,O_CLOEXEC","msg":"Unexpected file access","time":"2025-04-16T12:15:55Z"}
```
```json
{"BaseRuntimeMetadata":{"alertName":"Unexpected file access","arguments":{"flags":["O_RDONLY","O_CLOEXEC"],"path":"/lib/x86_64-linux-gnu/libnss_dns-2.31.so"},"infectedPID":22169,"severity":1,"timestamp":"2025-04-16T12:15:55.81043552Z","trace":{}},"CloudMetadata":null,"RuleID":"R0002","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"image":"docker.io/amitschendel/ping-app:latest","imageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d","namespace":"default","containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","podName":"ping-app","podNamespace":"default","workloadName":"ping-app","workloadNamespace":"default","workloadKind":"Pod"},"RuntimeProcessDetails":{"processTree":{"pid":2709,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2486,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":2734,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":22168,"cmdline":"/bin/sh -c ping -c 4 172.16.0.2,ls","comm":"sh","ppid":2734,"pcomm":"apache2","hardlink":"/bin/dash","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/dash","children":[{"pid":22169,"cmdline":"/bin/ping -c 4 172.16.0.2,ls","comm":"ping","ppid":22168,"pcomm":"sh","hardlink":"/bin/ping","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/ping"}]}]}]},"containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924"},"event":{"runtime":{"runtimeName":"containerd","containerId":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","containerName":"ping-app","containerImageName":"docker.io/amitschendel/ping-app:latest","containerImageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d"},"k8s":{"namespace":"default","podName":"ping-app","podLabels":{"app":"ping-app","kubescape.io/max-sniffing-time":"5m"},"containerName":"ping-app","owner":{}},"timestamp":1744805755810435520,"type":"normal"},"level":"error","message":"Unexpected file access: /lib/x86_64-linux-gnu/libnss_dns-2.31.so with flags O_RDONLY,O_CLOEXEC","msg":"Unexpected file access","time":"2025-04-16T12:15:55Z"}
```
```json
{"BaseRuntimeMetadata":{"alertName":"Unexpected file access","arguments":{"flags":["O_RDONLY","O_CLOEXEC"],"path":"/etc/nsswitch.conf"},"infectedPID":22169,"severity":1,"timestamp":"2025-04-16T12:15:55.81019379Z","trace":{}},"CloudMetadata":null,"RuleID":"R0002","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"image":"docker.io/amitschendel/ping-app:latest","imageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d","namespace":"default","containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","podName":"ping-app","podNamespace":"default","workloadName":"ping-app","workloadNamespace":"default","workloadKind":"Pod"},"RuntimeProcessDetails":{"processTree":{"pid":2709,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2486,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":2734,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":22168,"cmdline":"/bin/sh -c ping -c 4 172.16.0.2,ls","comm":"sh","ppid":2734,"pcomm":"apache2","hardlink":"/bin/dash","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/dash","children":[{"pid":22169,"cmdline":"/bin/ping -c 4 172.16.0.2,ls","comm":"ping","ppid":22168,"pcomm":"sh","hardlink":"/bin/ping","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/ping"}]}]}]},"containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924"},"event":{"runtime":{"runtimeName":"containerd","containerId":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","containerName":"ping-app","containerImageName":"docker.io/amitschendel/ping-app:latest","containerImageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d"},"k8s":{"namespace":"default","podName":"ping-app","podLabels":{"app":"ping-app","kubescape.io/max-sniffing-time":"5m"},"containerName":"ping-app","owner":{}},"timestamp":1744805755810193790,"type":"normal"},"level":"error","message":"Unexpected file access: /etc/nsswitch.conf with flags O_RDONLY,O_CLOEXEC","msg":"Unexpected file access","time":"2025-04-16T12:15:55Z"}
```
```json
{"BaseRuntimeMetadata":{"alertName":"Unexpected file access","arguments":{"flags":["O_RDONLY","O_CLOEXEC"],"path":"/etc/host.conf"},"infectedPID":22169,"severity":1,"timestamp":"2025-04-16T12:15:55.810226967Z","trace":{}},"CloudMetadata":null,"RuleID":"R0002","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"image":"docker.io/amitschendel/ping-app:latest","imageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d","namespace":"default","containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","podName":"ping-app","podNamespace":"default","workloadName":"ping-app","workloadNamespace":"default","workloadKind":"Pod"},"RuntimeProcessDetails":{"processTree":{"pid":2709,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2486,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":2734,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":22168,"cmdline":"/bin/sh -c ping -c 4 172.16.0.2,ls","comm":"sh","ppid":2734,"pcomm":"apache2","hardlink":"/bin/dash","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/dash","children":[{"pid":22169,"cmdline":"/bin/ping -c 4 172.16.0.2,ls","comm":"ping","ppid":22168,"pcomm":"sh","hardlink":"/bin/ping","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/ping"}]}]}]},"containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924"},"event":{"runtime":{"runtimeName":"containerd","containerId":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","containerName":"ping-app","containerImageName":"docker.io/amitschendel/ping-app:latest","containerImageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d"},"k8s":{"namespace":"default","podName":"ping-app","podLabels":{"app":"ping-app","kubescape.io/max-sniffing-time":"5m"},"containerName":"ping-app","owner":{}},"timestamp":1744805755810226967,"type":"normal"},"level":"error","message":"Unexpected file access: /etc/host.conf with flags O_RDONLY,O_CLOEXEC","msg":"Unexpected file access","time":"2025-04-16T12:15:55Z"}
```
```json
{"BaseRuntimeMetadata":{"alertName":"Unexpected file access","arguments":{"flags":["O_RDONLY","O_CLOEXEC"],"path":"/etc/resolv.conf"},"infectedPID":22169,"severity":1,"timestamp":"2025-04-16T12:15:55.81024497Z","trace":{}},"CloudMetadata":null,"RuleID":"R0002","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"image":"docker.io/amitschendel/ping-app:latest","imageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d","namespace":"default","containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","podName":"ping-app","podNamespace":"default","workloadName":"ping-app","workloadNamespace":"default","workloadKind":"Pod"},"RuntimeProcessDetails":{"processTree":{"pid":2709,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2486,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":2734,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":22168,"cmdline":"/bin/sh -c ping -c 4 172.16.0.2,ls","comm":"sh","ppid":2734,"pcomm":"apache2","hardlink":"/bin/dash","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/dash","children":[{"pid":22169,"cmdline":"/bin/ping -c 4 172.16.0.2,ls","comm":"ping","ppid":22168,"pcomm":"sh","hardlink":"/bin/ping","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/ping"}]}]}]},"containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924"},"event":{"runtime":{"runtimeName":"containerd","containerId":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","containerName":"ping-app","containerImageName":"docker.io/amitschendel/ping-app:latest","containerImageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d"},"k8s":{"namespace":"default","podName":"ping-app","podLabels":{"app":"ping-app","kubescape.io/max-sniffing-time":"5m"},"containerName":"ping-app","owner":{}},"timestamp":1744805755810244970,"type":"normal"},"level":"error","message":"Unexpected file access: /etc/resolv.conf with flags O_RDONLY,O_CLOEXEC","msg":"Unexpected file access","time":"2025-04-16T12:15:55Z"}
```

```json
{"BaseRuntimeMetadata":{"alertName":"Unexpected system call","arguments":{"syscall":"lseek"},"infectedPID":2709,"md5Hash":"4e79f11b07df8f72e945e0e3b3587177","sha1Hash":"b361a04dcb3086d0ecf960d3acaa776c62f03a55","severity":1,"size":"730 kB","timestamp":"2025-04-16T12:15:58.411292178Z","trace":{}},"CloudMetadata":null,"RuleID":"R0003","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"namespace":"default","containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","podName":"ping-app","podNamespace":"default","workloadName":"ping-app","workloadNamespace":"default","workloadKind":"Pod"},"RuntimeProcessDetails":{"processTree":{"pid":2709,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2486,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":15237,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},{"pid":2733,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},{"pid":2735,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},{"pid":2734,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},{"pid":2737,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},{"pid":2736,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":19194,"cmdline":"sh -c ping -c 4 172.16.0.2","comm":"sh","ppid":2736,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/bin/dash"}]}]},"containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924"},"event":{"runtime":{"runtimeName":"containerd","containerId":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924"},"k8s":{"node":"k0s-01","namespace":"default","podName":"ping-app","podLabels":{"app":"ping-app","kubescape.io/max-sniffing-time":"5m"},"containerName":"ping-app","owner":{}},"timestamp":1744805758411292178,"type":"normal"},"level":"error","message":"Unexpected system call: lseek","msg":"Unexpected system call","time":"2025-04-16T12:15:58Z"}
```


The fileaccess alert amongst the above messages is a definite smoking gun that a ping-utility wouldnt ever do.
So, this is great for standard runtime anomly behaviour... But, this lab is mostly for supply chain, so lets test that

### 2) A malicious behaviour cause by the artefact having been tampered with in the supply chain:

WIP: We will put something into the ping app , assuming the vendor didnt sign it, that has nothing to do with the ping







