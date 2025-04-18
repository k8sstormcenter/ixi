---
kind: course

title: Bill of Behaviour - introducing runtime profiles to supply chain security
description:
  We all need BoB - Dont take my word for it- Try it for yourself 

  This reference implementation is to showcase how to record a known benign behaviour, extract it, attach it to a signed OCI artefact,
  ingest it as a client, verify it and use it as base to detect malicious behaviour.



categories:
- security
- kubernetes

tagz:
- supplychain
- oci
- ebpf
- anomaly
- behaviour

createdAt: 2025-04-13
updatedAt: 2025-04-13

cover: __static__/cover-1.png
---
We &#x2764; supply chain security, thus people invented `SBOM`: the Bill of Materials.
Now, here comes the Bill of Behaviour `BoB`...


This "course" is currently WIP by Constanze and it's to be understood as a public co-lab for creating a `reference implementation` (like a devcontainer but with instructions and text) and you are invited to try it out and give her feedback, you can also become a co-author. 
__It is not a "course"__


Please note, that feedback both on the idea of `BoB` as well as the implementation (in this lab) are welcome starting Thursday April 17. It is still `very alpha`, at the moment we re focusing on the big ideas with the goal of this being acceptable as a standard (i.e. any tool choices should be optional), by as many vendors and users as possible.




You can contribute to the wiki in this 
 [kubescape fork](https://github.com/k8sstormcenter/kubescape/wiki/OCI-spec-to-contain-runtime%E2%80%90application%E2%80%90profile-to-inform-seccomp-and-or-alerting-on-integrity-violations).

The source code of this course is in https://github.com/k8sstormcenter/ixi 
and the content (like k0s config, kubescape config) is here: https://github.com/k8sstormcenter/honeycluster

