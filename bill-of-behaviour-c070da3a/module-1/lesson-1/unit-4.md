---
kind: unit

title: Verify the anomaly detection

name: hello-test
---


## CUSTOMER SIDE SKETCH  (this will be moved into the Module 3)


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
curl localhost:8080/ping.php?ip=172.16.0.2;ls
```
In the other tab, you should now see unexpected things:
```json

```

### 2) A malicious behaviour cause by the artefact having been tampered with in the supply chain:

WIP: We will put something into the ping app , assuming the vendor didnt sign it, that has nothing to do with the ping







