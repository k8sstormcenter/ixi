---
kind: unit

title: Releaseing the BoB into production


name: bob-prod
slug: 2
---
__THIS PART WILL SHOW HOW BOBCTL IMPLEMENTS BOB-INSTALL__

Assuming you are the customer, and all the `testing` and `merging` has been concluded.

You may now opt to use the `runtime security` rules in your production environment for anomaly detection.



### Part 2: Usage of BoB in production


Tag the release as stable:

```shell
bobctl tag artifact oci://registry.iximiuz.com/8sstormcenter/manifests/honey:$(git tag --points-at HEAD) \
  --tag stable
```

Deploy the latest stable build on the production cluster:

```yaml
apiVersion: source.k8sstormcenter.io/v1alpha1
kind: OCIRepository
metadata:
  name: k8sstormcenter-honey
  namespace: default
spec:
  interval: 5m
  url: oci://registry.iximiuz.com/k8sstormcenter/manifests/honey
  ref:
    tag: stable
```



