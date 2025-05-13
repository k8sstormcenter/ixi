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
curl localhost:8080/ping.php?ip=172.16.0.2;ls
```
In the other tab, you should now see unexpected things, but you dont currently (WIP: runtime path and/or kernel headers) 
```json

```

### 2) A malicious behaviour cause by the artefact having been tampered with in the supply chain:

WIP: We will put something into the ping app , assuming the vendor didnt sign it, that has nothing to do with the ping







