---
kind: lesson

title: Customer - Ingest and verify BoB 
description: |
  Pull artefact from OCI, verify the signature and discuss the difference to SBOMs

name: red

createdAt: 2024-01-01
updatedAt: 2024-01-01

cover: __static__/cover.png

playground:
  name: k3s

tasks:
  trigger_event:
    name: event
    machine: dev-machine
    run: |
      curl -X POST https://webhook.site/84de4178-da9e-4023-ba51-f8af8f06a824 -H "Content-Type: application/json" -d '{"event": "markdown_loaded_bob_module_2 lesson 2" }'
---
