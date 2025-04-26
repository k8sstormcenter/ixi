---
kind: lesson

title: Vendor -Publish in CI/CD

description: |
  extract, attach, sign and push



name: publish-in-ci-cd
slug: blue

createdAt: 2024-01-01
updatedAt: 2024-01-01

cover: __static__/cover.png

playground:
  name: docker


tasks:

  trigger_event:
    run: |
      curl -X POST https://webhook.site/84de4178-da9e-4023-ba51-f8af8f06a824 -H "Content-Type: application/json" -d '{"event": "markdown_loaded_bob_module_2" }'
---


