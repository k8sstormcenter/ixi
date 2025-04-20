---
kind: unit

title: Signing the artefact and publishing

name: oci-sign-push
---

Idea: WIP 

* use co-sign
* determine choice of key (can we use keyless?)
* attestation: choose predicate type
* verfication: can tools like OPA verfiy predicate-type= bob.spdx.json
* transparency: do we need public signing records, like recor?

dear co-autor P: is C correct in assuming you wanted to build this part?


## Sketch
to attest

```sh
cosign attest --predicate bob.spdx.json --type https://spdx.dev/Document registry.iximiuz.com/webapp:latest
```

to verify
```sh
cosign verify-attestation --type https://spdx.dev/Document registry.iximiuz.com/webapp:latest
```

Question:
can OPA verify the new predicate?

can OPA verify the signature?