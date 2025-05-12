---
kind: lesson

title: 'Setup of kubernetes with k0s and kubescape'
description: |
  Prerequisites and deployment of "sample app" for which we create a Bill of Behaviour

name: green
slug: debug-1

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

  trigger_event:
    run: |
      curl -X POST https://webhook.site/84de4178-da9e-4023-ba51-f8af8f06a824 -H "Content-Type: application/json" -d '{"event": "markdown_loaded_bob_module_4 " }'

  git_clone_1:
    run: |
      [[  -d /home/laborant/honeycluster/.git   ]]


  make_1:
    needs:
    - git_clone_1
    run: |
      [[ -z $(kubectl get pods -n honey -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -v True) && "$(sleep 45 && kubectl get namespace honey -o jsonpath='{.status.phase}')"=="Active"  ]]

  appprofempty_1:
    needs:
    - make_1
    run: |
      [[ -z "$(kubectl get applicationprofile -A | tail -n +2)" ]]

  webapp_1:
    run: |
      [[ "$(kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}')" == "True"  ]]
  
  profilecomplete_1:
    run: |
      [[ "$(kubectl get applicationprofile pod-ping-app -o jsonpath='{.metadata.annotations.kubescape\.io/status}')" == "completed" ]]


---
