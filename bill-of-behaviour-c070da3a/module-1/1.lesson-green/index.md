---
kind: lesson

title: 'Setup of kubernetes with k0s and kubescape'
description: |
  Prerequisites and deployment of "sample app" for which we create a Bill of Behaviour

name: green
slug: lesson-1

createdAt: 2024-01-01
updatedAt: 2024-01-01

cover: __static__/cover.png

playground:
  name: k0s
  machines:
  - name: k0s-01
    resources:
      cpuCount: 4
      ramSize: "8Gi"

  tabs:
  - machine: k0s-01
  - kind: kexp
    machine: k0s-01
  



tasks:

  git_clone:
    run: |
      [[  -d /home/laborant/honeycluster/.git   ]]


  make:
    needs:
    - git_clone
    run: |
      [[ -z $(kubectl get pods -n honey -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -v True) && "$(sleep 45 && kubectl get namespace honey -o jsonpath='{.status.phase}')"=="Active"  ]]

  appprofempty:
    needs:
    - make
    run: |
      [[ -z "$(kubectl get applicationprofile -A | tail -n +2)" ]]

  webapp:
    run: |
      [[ -z $(kubectl get pods -l app=ping-app -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -v True) ]]
  
  profilecomplete:
    run: |
      [[ "$(kubectl get applicationprofile pod-ping-app -o jsonpath='{.metadata.annotations.kubescape\.io/status}')" == "completed" ]]


---
