---
kind: lesson

title: 'Vendor produces Bill of Behaviour for their application/product'
description: |
  Prerequisites and deployment of "sample app" for which we create a Bill of Behaviour

name: green-1
slug: lesson-1

createdAt: 2024-01-01
updatedAt: 2024-01-01

cover: __static__/cover.png


playground: 
  name: k8s-omni
---

tasks:
  git_clone:
    run: |
      [[  -d /home/laborant/honeycluster/.git   ]]

  make:
    run: |
      [[ $(kubectl get pods -n honey --no-headers 2>/dev/null | wc -l) -gt 0 ]] && \
      [[ $(kubectl wait --for=condition=Ready --all pods -n honey --timeout=600s && echo "true" || echo "false") == "true" ]]

  webapp:
    run: |
      [[ "$(kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}')" == "True"  ]]
  
  profilecomplete:
    run: |
      [[ "$(kubectl get applicationprofile replicaset-$(kubectl get replicaset -n default -o jsonpath='{.items[0].metadata.name}') -o jsonpath='{.metadata.annotations.kubescape\.io/status}')" == "completed" ]]


---

<!--
  name: k8s-omni
  machines:
  - name: dev-machine
    resources:
      cpuCount: 2
      ramSize: "4Gi"
  - name:  cplane-01
    resources:
      cpuCount: 4
      ramSize: "4Gi"
  - name:  node-01
    resources:
      cpuCount: 2
      ramSize: "4Gi"
    
  tabs:
    - machine: dev-machine
    - machine: cplane-01
    - machine: node-01
    - kind: kexp
      machine: dev-machine
    - kind: terminal
      machine: dev-machine
    - kind: terminal
      machine: cplane-01
    - kind: terminal
      machine: node-01
--!>