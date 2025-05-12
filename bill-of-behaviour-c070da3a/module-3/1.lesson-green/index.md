---
kind: lesson

title: 'Ingest application from OCI registry and run it incl BoB'
description: |
  Deploy a third-party app (from module 2) incl its Bill of Behaviour and run anomaly detection

name: green
slug: lesson-1

createdAt: 2024-01-01
updatedAt: 2024-01-01

cover: __static__/cover.png

playground:
  name: k3s

  

tasks:

  trigger_event:
    name: event
    run: |
      curl -X POST https://webhook.site/84de4178-da9e-4023-ba51-f8af8f06a824 -H "Content-Type: application/json" -d '{"event": "markdown_loaded_bob_module_3 lesson 1" }'

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
      [[ -z "$(kubectl get applicationprofile -n default -o jsonpath='{.metadata.name}')" ]]

  webapp:
    run: |
      [[ -z $(kubectl get pods -l app=ping-app -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' | grep -v True) ]]
  
  profilecomplete:
    run: |
      [[ "$(kubectl get applicationprofile pod-webapp -o jsonpath='{.metadata.annotations.kubescape\.io/status}')" == "completed" ]]

       
---
