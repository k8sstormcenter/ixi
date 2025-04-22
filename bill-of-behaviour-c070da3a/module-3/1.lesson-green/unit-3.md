---
kind: unit

title: Some Usecases

name: bob-usecase
---

WIP: currently copy paste from module 1 lesson 3.

``` json
spec:                                                                            
  6   architectures:                                                                 
  7   - amd64                                                                        
  8   containers:                                                                    
  9   - capabilities:                                                                
 10     - NET_RAW                                                                    
 11     - SETUID                                                                     
 12     endpoints: null                                                              
 13     execs:                                                                       
 14     - args:                                                                      
 15       - /bin/sh                                                                  
 16       - -c                                                                       
 17       - ping -c 4 172.16.0.2                                                     
 18       path: /bin/sh                                                              
 19     - args:                                                                      
 20       - /bin/ping                                                                
 21       - -c                                                                       
 22       - "4"                                                                      
 23       - 172.16.0.2                                                               
 24       path: /bin/ping                                                            
 25     imageID: docker.io/amitschendel/ping-app@sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0ca
be8488de77405149c524d
 26     imageTag: docker.io/amitschendel/ping-app:latest                             
 27     name: ping-app                                                               
 28     opens:                                                                       
 29     - flags:                                                                     
 30       - O_CLOEXEC                                                                
 31       - O_RDONLY                                                                 
 32       path: /usr/lib/x86_64-linux-gnu/libunistring.so.2.1.0                      
 33     - flags:                                                                     
 34       - O_RDONLY                                                                 
 35       path: /var/www/html/ping.php 
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
{"level":"info","ts":"2025-04-16T12:06:57Z","msg":"stop monitor on container - monitoring time ended","container ID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","k8s workload":"default/ping-app/ping-app"}
```
Also, in the crd annotation, you will find the status completed now. The completion is `partial`, which 
we may ignore here (accrd to upstream documentation it means that the app was already started when we were profiling it, but this is what we want in this case)

```yaml
kubectl describe applicationprofile pod-ping-app 
...
...
Annotations:  kubescape.io/completion: partial
              kubescape.io/instance-id: apiVersion-v1/namespace-default/kind-Pod/name-ping-app
              kubescape.io/resource-size: 9
              kubescape.io/status: completed
```

Now, we must save this above file onto disk:

```sh
kubectl describe applicationprofile pod-ping-app  > pod-ping-app.yaml
```


<!-- [Debug: restart the nodeagent]

```sh
kubectl rollout restart ds -n honey node-agent 
``` -->

## Test (this will be moved into the client side)

@Peter: now i need to implement the extract this profile into yaml, attach it to container, sign, push, ....lalala
eventually, a client will do almost the exact same thing, and pull it again, ... this is the sketch of the `alert` of
`malicious` behaviour.



So, we are done here, but we could - just for kicks - verify that kubescape is now watching for anything that was not previously recorded as `benign` .

### A malicious runtime behaviour by executing a simple injection like so:

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
{"BaseRuntimeMetadata":{"alertName":"Unexpected file access","arguments":{"flags":["O_RDONLY","O_CLOEXEC"],"path":"/etc/hosts"},"infectedPID":22169,"severity":1,"timestamp":"2025-04-16T12:15:55.810352331Z","trace":{}},"CloudMetadata":null,"RuleID":"R0002","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"image":"docker.io/amitschendel/ping-app:latest","imageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d","namespace":"default","containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","podName":"ping-app","podNamespace":"default","workloadName":"ping-app","workloadNamespace":"default","workloadKind":"Pod"},"RuntimeProcessDetails":{"processTree":{"pid":2709,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2486,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":2734,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":22168,"cmdline":"/bin/sh -c ping -c 4 172.16.0.2,ls","comm":"sh","ppid":2734,"pcomm":"apache2","hardlink":"/bin/dash","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/dash","children":[{"pid":22169,"cmdline":"/bin/ping -c 4 172.16.0.2,ls","comm":"ping","ppid":22168,"pcomm":"sh","hardlink":"/bin/ping","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/ping"}]}]}]},"containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924"},"event":{"runtime":{"runtimeName":"containerd","containerId":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","containerName":"ping-app","containerImageName":"docker.io/amitschendel/ping-app:latest","containerImageDigest":"sha256:99fe0f297bbaeca1896219486de8d777fa46bd5b0cabe8488de77405149c524d"},"k8s":{"namespace":"default","podName":"ping-app","podLabels":{"app":"ping-app","kubescape.io/max-sniffing-time":"5m"},"containerName":"ping-app","owner":{}},"timestamp":1744805755810352331,"type":"normal"},"level":"error","message":"Unexpected file access: /etc/hosts with flags O_RDONLY,O_CLOEXEC","msg":"Unexpected file access","time":"2025-04-16T12:15:55Z"}
```
```json
{"BaseRuntimeMetadata":{"alertName":"Unexpected system call","arguments":{"syscall":"lseek"},"infectedPID":2709,"md5Hash":"4e79f11b07df8f72e945e0e3b3587177","sha1Hash":"b361a04dcb3086d0ecf960d3acaa776c62f03a55","severity":1,"size":"730 kB","timestamp":"2025-04-16T12:15:58.411292178Z","trace":{}},"CloudMetadata":null,"RuleID":"R0003","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"namespace":"default","containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924","podName":"ping-app","podNamespace":"default","workloadName":"ping-app","workloadNamespace":"default","workloadKind":"Pod"},"RuntimeProcessDetails":{"processTree":{"pid":2709,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2486,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":15237,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},{"pid":2733,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},{"pid":2735,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},{"pid":2734,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},{"pid":2737,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},{"pid":2736,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":2709,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","children":[{"pid":19194,"cmdline":"sh -c ping -c 4 172.16.0.2","comm":"sh","ppid":2736,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/bin/dash"}]}]},"containerID":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924"},"event":{"runtime":{"runtimeName":"containerd","containerId":"8ac882eefce545c63fdad8d090f7d6074389301c0474b9aed810f207fa62e924"},"k8s":{"node":"k0s-01","namespace":"default","podName":"ping-app","podLabels":{"app":"ping-app","kubescape.io/max-sniffing-time":"5m"},"containerName":"ping-app","owner":{}},"timestamp":1744805758411292178,"type":"normal"},"level":"error","message":"Unexpected system call: lseek","msg":"Unexpected system call","time":"2025-04-16T12:15:58Z"}
```

OK: this is where I am at... Now implementing how to get this into an image, and read it out.
And test, which parts of the following profile translate across clusters, and which dont
