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
  machines:
   - name:  dev-machine
   - name:  cplane-01
   - name:  node-01
   - name:  node-02
  tabs:
  - machine: dev-machine
  


tasks:
  git_clone_k8s:
    name: git_clone_k8s
    machine: dev-machine
    run: |
      [[  -d /home/laborant/honeycluster/.git   ]]

  trigger_event:
    name: event
    machine: dev-machine
    run: |
      curl -X POST https://webhook.site/84de4178-da9e-4023-ba51-f8af8f06a824 -H "Content-Type: application/json" -d '{"event": "markdown_loaded_bob_module_1" }'

  

  verify_kubescape_health:
    machine: node-01
    timeout_seconds: 30
    run: |
      # Check node status
      NODE_STATUS=$(kubectl get nodes -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}')

      # Check pod status
      POD_STATUS=$(kubectl get pods -A -o jsonpath='{.items[*].status.phase}' | tr ' ' '\n' | sort | uniq)
      KUBESCAPE_STATUS=$(kubectl get pods -n honey -l app.kubernetes.io/instance=kubescape -o jsonpath='{.items[*].status.phase}' | tr ' ' '\n' | sort | uniq)

      if [[ "$NODE_STATUS" == "True True True" ]] && \
         [[ "$POD_STATUS" == "Running" ]] && \
         [[ "$KUBESCAPE_STATUS" == "Running" ]] ; then
        echo "Installation of kubescape verified successfully!"
        exit 0
      else
        exit 1
      fi

  webapp:
    machine: dev-machine
    run: |
      [[ "$(kubectl get pods -l app=webapp -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}')" == "True"  ]]

  
  profilecomplete:
    machine: dev-machine
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