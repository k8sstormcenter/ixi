---
kind: unit

title: Client Side verification of BoB

name: bob-test
slug: 1
---

Welcome back to kubernetes. Now, we are switching sides and becoming a `customer` who uses the `webapp` product.

We now use `k3s` for the first time, which is significantly different from the `vendor` setup to showcase how the BoB translates across tech-stacks.

In this first part on the `customer` side, we need to verify and unpack the BoB.

What this means is that there is a part where we pull the artefact and verify the signature.
Then, we test deploy the application including the BoB and verify the runtime-deployment.

Afterwards, the customer may choose to use the runtime-rules during production or adopt them to their own liking.




::remark-box
---
kind: warning
---
__It is crucial, that the vendor can only supply a BoB for a __subset__ of all possible runtime configurations__, this part can
be directly verified during the `BoB test`, the customer is expected to modify the bob.values or merge the bob.yaml into 
their own environment.
::

### Diagram: BoB installation and verification 

```mermaid
sequenceDiagram
    actor me
    participant sc as BoB<br><br>source-controller
    participant git as OCI<br><br>registry
    participant dc as BoB<br><br>deployment-controller
    participant kube as Kubernetes<br><br>api-server


    me->>sc: 1. bobctl "install --values"
    sc->>git: 2. pull BoB artifact
    sc-->>sc: 3. verify signatures
    sc-->>sc: 4. unbundle
    sc->>sc: 5. apply values
    sc-->>me: 6. confirm generated artefacts
    me->>dc: 7. initiate deployment
    dc->>kube: 8. install kubescape nodeagent
    kube->>dc: 9. confirm kubescape crd and config
    dc->>kube: 10. apply original BoB
    dc-->>dc: 11. wait for BoB test
    kube->>dc: 12. collect test report
    dc->>me: 13. final test report
    me-->>dc: 14. adapt BoB
    dc-->>dc: 15. merge BoB
    dc->>kube: 16. update BoB for production
```

### Part 1 Verfication aka BoB Test

We imagine that the `BoB-test` would be run via automation on a lower environment, on which load-tests are being conducted.
Just like in most installations, we assume the `values` will be iteratively adapted until stable.

```mermaid
flowchart LR

A --> F[has two envs with CD, adapts ``bob.values` until happy]
F --> B
A((User)) --> B(Git Repository)
B --> C((CI runs Bob-test on Staging-env))
C --> D[Container Registry ]
D --> G[pull and use inside production Cluster]
G --> H((Detect anomaly))
```

Once considered stable, the merged bob.yaml and the adapted bob.values can be used in production , without the test phase.


::remark-box
---
kind: warning
---
TODO C: sketch here how to run bob-test in CI
::

### Merging multiple BoBs 

Lets talk about how BoBs must be `additive` and `composable` .

And also how they must be customizable to the clients different environments. 


::remark-box
---
kind: warning
---
TODO C: sketch here how to merge artefacts
::

