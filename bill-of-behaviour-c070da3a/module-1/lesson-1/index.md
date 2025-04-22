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
      [[ $(kubectl get pods -n honey --no-headers 2>/dev/null | wc -l) -gt 0 ]] && \
      [[ $(kubectl wait --for=condition=Ready --all pods -n honey --timeout=600s && echo "true" || echo "false") == "true" ]]


  appprofempty:
    needs:
    - make
    run: |
      [[ -z "$(kubectl get applicationprofile -A | tail -n +2)" ]]

  webapp:
    run: |
      [[ "$(kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}')" == "True"  ]]
  
  profilecomplete:
    run: |
      [[ "$(kubectl get applicationprofile pod-webapp -o jsonpath='{.metadata.annotations.kubescape\.io/status}')" == "completed" ]]


---
