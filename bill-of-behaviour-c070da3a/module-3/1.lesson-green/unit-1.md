---
kind: unit

title: Consume the app on client cluster

name: consume-app-install
---

Pretending we are now the consumer/user of `webapp` , we have our own infrastructure.
This consumer uses k3s, which is another slim kubernetes flavour from a different vendor than k0s.

We, ll cover the following
 
* Get to know our k3s installation
* Deploy kubescape in a slightly different config to give us anomaly detection
* Follow the 2-step installation process
* Watch it for the two types of anomalies
  

## 0 Clone repo
Again, lets clone the same repo, this is a fresh playground
```git
git clone https://github.com/k8sstormcenter/honeycluster.git
cd honeycluster
git checkout 152-implement-bill-of-behaviour-demo-lab 
```
::simple-task
---
:tasks: tasks
:name: git_clone
---
#active
Waiting for you to clone the repo


#completed
Congrats! 
::

## 1 Install kubescape and wait until it's up and running

```sh
make kubescape-bob-kind
```
```bash
kubectl get pods -n honey -l app.kubernetes.io/instance=kubescape
```
You want the `STATUS` of all pods to be `Running`, like so:
```
laborant@dev-machine:webapp_t$ kubectl get pods -n honey -l app.kubernetes.io/instance=kubescape
NAME                                READY   STATUS    RESTARTS   AGE
grype-offline-db-579c6cbc47-rvgqk   1/1     Running   0          20m
node-agent-b4qmg                    2/2     Running   0          20m
node-agent-tgs8f                    2/2     Running   0          20m
node-agent-vslk6                    2/2     Running   0          20m
operator-559b868885-kr8dt           1/1     Running   0          20m
storage-79d6fd9785-gdpx2            1/1     Running   0          20m
```


Check out the Explorer tab :tab-locator-inline{text='Explorer' name='Explorer'}, then navigate to `All Objects`
and expand, hover and toggle the 👁️-Icon on `spdx.softwarecomposition.kubescape.io/v1beta1` -> `ApplicationProfile` , then navigate to
the bottom `Watched Objects` . You are now watching for these Application Profiles and no longer need to filter

## 2 pull down artefact (not yet implemented)
WIP: 

```sh
some mystical command like ctr pull
```

We will simply use our images `k8sstormcenter/webapp:latest` and `k8sstormcenter/webapp-t:latest`
which are multi-arch reproductions of `docker.io/amitschendel/ping-app:latest` with `-t` meaning it was tampered.
Their Dockerfiles (and github-workflows)are

https://github.com/k8sstormcenter/honeycluster/blob/152-implement-bill-of-behaviour-demo-lab/.github/workflows/publish-image-kubescape-webapp.yml

## 3 deploy artefact (first without tampering)

Ok, now we pretend to just install that `webapp` image , that we as customer think is the correct one.

So, this (will be) the exact same artefact as in Module-1, just on a different tech stack now:
```sh
cd traces/kubescape-verify/attacks/webapp/
chmod +x setup.sh
./setup.sh
```

## 4 Use the artefact in a functional, benign way
So, we again, do the almost same things:

This app was made for pinging, so we ping

Open a new tab :tab-locator-inline{text='new terminal' machine='dev-machine' :new=true}
Let's ping:

```sh
curl localhost:8080/ping.php?ip=172.16.0.2
```
if that works, let it loop 

```sh
while true; do curl localhost:8080/ping.php?ip=172.16.0.2; sleep 10; done
```
Do not kill the looping.
Please, switch back to the original :tab-locator-inline{text='dev-machine' name='dev-machine'} tab, and proceed



## 5 Wait for kubescape to settle

TODO: replace with more production like method.

The `garbage out, patch in` method :

We ll wait until we have an application profile again and we ll throw it away.


Lets check the configuration in order to understand if the setup is any different from Module 1:
```sh
kubectl describe cm -n honey ks-cloud-config
kubectl describe RuntimeRuleAlertBinding all-rules-all-pods
```

```sh
kubectl get applicationProfile -A
```
```
laborant@dev-machine:webapp_t$ kubectl get applicationProfile -A
NAMESPACE   NAME                           CREATED AT
default     replicaset-webapp-75c688bfc4   2025-04-25T12:38:28Z
```

```sh
export rs=$(kubectl get replicaset -n default -o jsonpath='{.items[0].metadata.name}')
kubectl describe applicationprofile replicaset-$rs
```
```sh
kubectl get applicationProfile replicaset-$rs  -o yaml > ~/originalappprofile.yaml
```

now edit that profile (so it keeps it name), but use the content of the one from Module 1!!!
```sh   
echo $rs
envsubst < /home/laborant/honeycluster/traces/kubescape-verify/attacks/webapp/bob_applicationprofile.yaml > /home/laborant/honeycluster/traces/kubescape-verify/attacks/webapp/bob.yaml
```

`patch` the ping-profile:

```sh
kubectl apply -f /home/laborant/honeycluster/traces/kubescape-verify/attacks/webapp/bob.yaml
```
Make sure you didnt wake ~~the dragon~~ kubescape
```
kubectl logs -n honey -l app=node-agent
```
there should be no additional logs, only the stop of the above profile, similar to:

```json
{"level":"info","ts":"2025-04-25T16:25:13Z","msg":"RBCache - ruleBinding added/modified","name":"/all-rules-all-pods"}
{"level":"info","ts":"2025-04-25T17:05:15Z","msg":"start monitor on container","container ID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8","k8s workload":"default/webapp-8b697d7f9-h9mx4/ping-app","ContainerImageDigest":"sha256:31eb54dc4f5e3537a807e1a5cbc2de9d6c0a5f4e423a5137627e664748f03d7f","ContainerImageName":"ghcr.io/k8sstormcenter/webapp:latest"}
{"level":"info","ts":"2025-04-25T17:10:15Z","msg":"stop monitor on container - monitoring time ended","container ID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8","k8s workload":"default/webapp-8b697d7f9-h9mx4/ping-app"}
```


Quick Summary:

We as customer deployed `webapp`, we didnt check its signature, we recorded a profile and threw away that profile by overwriting it with the profile from Module 1, aka `BoB`.
We did this to trick kubescape into believing, it has recorded the supplied `BoB`  (the metadata of the profile are correct). 

## 6 watch how k3s is different from k8s

Check your looping tab . It should still be doing its thing.

However, did you notice that kubescape isnt showing us any logs?

Given our exessively limited `benign behaviour`, this isnt super interesting.

Since about `90` percent of the files are linked libs that are loaded at startup: lets
restart the `pod` NOT the `deployment` . We need the `deployment` to retain the same name.

Open a third terminal and:

```
kubectl logs -n honey -l app=node-agent --tail=-1 -f
```
back in another terminal:
```
kubectl rollout restart deployment webapp
```


Now, we noticed that we had `not` recorded the death of `webapp` and its showing up
as deviation, lets analyse:

```json
{
  "BaseRuntimeMetadata":{
    "alertName":"Unexpected capability used",
    "arguments":{
      "capability":"KILL",
      "syscall":"kill"
    },
    "infectedPID":23368,
    "md5Hash":"4e79f11b07df8f72e945e0e3b3587177",
    "sha1Hash":"b361a04dcb3086d0ecf960d3acaa776c62f03a55",
    "severity":5,
    "size":"730 kB",
    "timestamp":"2025-04-25T17:42:59.871829481Z",
    "trace":{}
  },
  "CloudMetadata":null,
  "RuleID":"R0004",
  "RuntimeK8sDetails":{
    "clusterName":"honeycluster",
    "containerName":"ping-app",
    "hostNetwork":false,
    "image":"ghcr.io/k8sstormcenter/webapp:latest",
    "imageDigest":"sha256:31eb54dc4f5e3537a807e1a5cbc2de9d6c0a5f4e423a5137627e664748f03d7f",
    "namespace":"default",
    "containerID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8",
    "podName":"webapp-8b697d7f9-h9mx4",
    "podNamespace":"default",
    "workloadName":"webapp",
    "workloadNamespace":"default",
    "workloadKind":"Deployment"
  },
  "RuntimeProcessDetails":{
    "processTree":{
      "pid":23368,
      "cmdline":"/usr/sbin/apache2 -DFOREGROUND",
      "comm":"apache2",
      "ppid":22855,
      "pcomm":"containerd-shim",
      "hardlink":"/usr/sbin/apache2",
      "uid":0,
      "gid":0,
      "startTime":"0001-01-01T00:00:00Z",
      "upperLayer":false,
      "cwd":"/var/www/html",
      "path":"/usr/sbin/apache2"
    },
    "containerID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8"
  },
  "event":{
    "runtime":{
      "runtimeName":"containerd",
      "containerId":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8",
      "containerName":"ping-app",
      "containerImageName":"ghcr.io/k8sstormcenter/webapp:latest",
      "containerImageDigest":"sha256:31eb54dc4f5e3537a807e1a5cbc2de9d6c0a5f4e423a5137627e664748f03d7f"
    },
    "k8s":{
      "namespace":"default",
      "podName":"webapp-8b697d7f9-h9mx4",
      "podLabels":{
        "app":"webapp",
        "pod-template-hash":"8b697d7f9"
      },
      "containerName":"ping-app",
      "owner":{}
    },
    "timestamp":1745602979871829481,
    "type":"normal"
  },
  "level":"error",
  "message":"Unexpected capability used (capability KILL used in syscall kill)",
  "msg":"Unexpected capability used",
  "time":"2025-04-25T17:42:59Z"
}{
  "BaseRuntimeMetadata":{
    "alertName":"Unexpected system call",
    "arguments":{
      "syscall":"clock_nanosleep"
    },
    "infectedPID":23368,
    "md5Hash":"4e79f11b07df8f72e945e0e3b3587177",
    "sha1Hash":"b361a04dcb3086d0ecf960d3acaa776c62f03a55",
    "severity":1,
    "size":"730 kB",
    "timestamp":"2025-04-25T17:43:01.774765335Z",
    "trace":{}
  },
  "CloudMetadata":null,
  "RuleID":"R0003",
  "RuntimeK8sDetails":{
    "clusterName":"honeycluster",
    "containerName":"ping-app",
    "hostNetwork":false,
    "namespace":"default",
    "containerID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8",
    "podName":"webapp-8b697d7f9-h9mx4",
    "podNamespace":"default",
    "workloadName":"webapp",
    "workloadNamespace":"default",
    "workloadKind":"Deployment"
  },
  "RuntimeProcessDetails":{
    "processTree":{
      "pid":23368,
      "cmdline":"apache2 -DFOREGROUND",
      "comm":"apache2",
      "ppid":22855,
      "pcomm":"containerd-shim",
      "uid":0,
      "gid":0,
      "startTime":"0001-01-01T00:00:00Z",
      "cwd":"/var/www/html",
      "path":"/usr/sbin/apache2"
    },
    "containerID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8"
  },
  "event":{
    "runtime":{
      "runtimeName":"containerd",
      "containerId":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8"
    },
    "k8s":{
      "node":"node-02",
      "namespace":"default",
      "podName":"webapp-8b697d7f9-h9mx4",
      "podLabels":{
        "app":"webapp",
        "pod-template-hash":"8b697d7f9"
      },
      "containerName":"ping-app",
      "owner":{}
    },
    "timestamp":1745602981774765335,
    "type":"normal"
  },
  "level":"error",
  "message":"Unexpected system call: clock_nanosleep",
  "msg":"Unexpected system call",
  "time":"2025-04-25T17:43:01Z"
}{
  "BaseRuntimeMetadata":{
    "alertName":"Unexpected system call",
    "arguments":{
      "syscall":"getpgid"
    },
    "infectedPID":23368,
    "md5Hash":"4e79f11b07df8f72e945e0e3b3587177",
    "sha1Hash":"b361a04dcb3086d0ecf960d3acaa776c62f03a55",
    "severity":1,
    "size":"730 kB",
    "timestamp":"2025-04-25T17:43:01.800888956Z",
    "trace":{}
  },
  "CloudMetadata":null,
  "RuleID":"R0003",
  "RuntimeK8sDetails":{
    "clusterName":"honeycluster",
    "containerName":"ping-app",
    "hostNetwork":false,
    "namespace":"default",
    "containerID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8",
    "podName":"webapp-8b697d7f9-h9mx4",
    "podNamespace":"default",
    "workloadName":"webapp",
    "workloadNamespace":"default",
    "workloadKind":"Deployment"
  },
  "RuntimeProcessDetails":{
    "processTree":{
      "pid":23368,
      "cmdline":"apache2 -DFOREGROUND",
      "comm":"apache2",
      "ppid":22855,
      "pcomm":"containerd-shim",
      "uid":0,
      "gid":0,
      "startTime":"0001-01-01T00:00:00Z",
      "cwd":"/var/www/html",
      "path":"/usr/sbin/apache2"
    },
    "containerID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8"
  },
  "event":{
    "runtime":{
      "runtimeName":"containerd",
      "containerId":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8"
    },
    "k8s":{
      "node":"node-02",
      "namespace":"default",
      "podName":"webapp-8b697d7f9-h9mx4",
      "podLabels":{
        "app":"webapp",
        "pod-template-hash":"8b697d7f9"
      },
      "containerName":"ping-app",
      "owner":{}
    },
    "timestamp":1745602981800888956,
    "type":"normal"
  },
  "level":"error",
  "message":"Unexpected system call: getpgid",
  "msg":"Unexpected system call",
  "time":"2025-04-25T17:43:01Z"
}{
  "BaseRuntimeMetadata":{
    "alertName":"Unexpected system call",
    "arguments":{
      "syscall":"kill"
    },
    "infectedPID":23368,
    "md5Hash":"4e79f11b07df8f72e945e0e3b3587177",
    "sha1Hash":"b361a04dcb3086d0ecf960d3acaa776c62f03a55",
    "severity":1,
    "size":"730 kB",
    "timestamp":"2025-04-25T17:43:01.80241071Z",
    "trace":{}
  },
  "CloudMetadata":null,
  "RuleID":"R0003",
  "RuntimeK8sDetails":{
    "clusterName":"honeycluster",
    "containerName":"ping-app",
    "hostNetwork":false,
    "namespace":"default",
    "containerID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8",
    "podName":"webapp-8b697d7f9-h9mx4",
    "podNamespace":"default",
    "workloadName":"webapp",
    "workloadNamespace":"default",
    "workloadKind":"Deployment"
  },
  "RuntimeProcessDetails":{
    "processTree":{
      "pid":23368,
      "cmdline":"apache2 -DFOREGROUND",
      "comm":"apache2",
      "ppid":22855,
      "pcomm":"containerd-shim",
      "uid":0,
      "gid":0,
      "startTime":"0001-01-01T00:00:00Z",
      "cwd":"/var/www/html",
      "path":"/usr/sbin/apache2"
    },
    "containerID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8"
  },
  "event":{
    "runtime":{
      "runtimeName":"containerd",
      "containerId":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8"
    },
    "k8s":{
      "node":"node-02",
      "namespace":"default",
      "podName":"webapp-8b697d7f9-h9mx4",
      "podLabels":{
        "app":"webapp",
        "pod-template-hash":"8b697d7f9"
      },
      "containerName":"ping-app",
      "owner":{}
    },
    "timestamp":1745602981802410710,
    "type":"normal"
  },
  "level":"error",
  "message":"Unexpected system call: kill",
  "msg":"Unexpected system call",
  "time":"2025-04-25T17:43:01Z"
}{
  "BaseRuntimeMetadata":{
    "alertName":"Unexpected system call",
    "arguments":{
      "syscall":"unlink"
    },
    "infectedPID":23368,
    "md5Hash":"4e79f11b07df8f72e945e0e3b3587177",
    "sha1Hash":"b361a04dcb3086d0ecf960d3acaa776c62f03a55",
    "severity":1,
    "size":"730 kB",
    "timestamp":"2025-04-25T17:43:01.803887155Z",
    "trace":{}
  },
  "CloudMetadata":null,
  "RuleID":"R0003",
  "RuntimeK8sDetails":{
    "clusterName":"honeycluster",
    "containerName":"ping-app",
    "hostNetwork":false,
    "namespace":"default",
    "containerID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8",
    "podName":"webapp-8b697d7f9-h9mx4",
    "podNamespace":"default",
    "workloadName":"webapp",
    "workloadNamespace":"default",
    "workloadKind":"Deployment"
  },
  "RuntimeProcessDetails":{
    "processTree":{
      "pid":23368,
      "cmdline":"apache2 -DFOREGROUND",
      "comm":"apache2",
      "ppid":22855,
      "pcomm":"containerd-shim",
      "uid":0,
      "gid":0,
      "startTime":"0001-01-01T00:00:00Z",
      "cwd":"/var/www/html",
      "path":"/usr/sbin/apache2"
    },
    "containerID":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8"
  },
  "event":{
    "runtime":{
      "runtimeName":"containerd",
      "containerId":"d4d78869d6b20066565d10c39fa37d1c6d3d5d83161b4d7b3d75783d53653ae8"
    },
    "k8s":{
      "node":"node-02",
      "namespace":"default",
      "podName":"webapp-8b697d7f9-h9mx4",
      "podLabels":{
        "app":"webapp",
        "pod-template-hash":"8b697d7f9"
      },
      "containerName":"ping-app",
      "owner":{}
    },
    "timestamp":1745602981803887155,
    "type":"normal"
  },
  "level":"error",
  "message":"Unexpected system call: unlink",
  "msg":"Unexpected system call",
  "time":"2025-04-25T17:43:01Z"
}
```


Discuss that those CAPs and SYSCALLS are all related to the restart

TODO: trace out the restart to proof OR make this a challenge for the audience to do


## 8) more benign traffic after restart

In case it hangs, kill the port-fwd and restart it:
```sh
kill -9 $(sudo lsof -t -i :8080)
kubectl port-forward svc/webapp 8080:80 2>&1 >/dev/null &
while true; do curl localhost:8080/ping.php?ip=172.16.0.2; sleep 10; done
```


Ok so now you ll get more `supposed mismatches`  , but if we compare it with our `bob.yaml` those are supposed
to be known, so ... not sure how to teach kubescape to not emit them

WIP: more debugging is needed

### Diff 1 that shouldnt be a diff

```json
{
   "BaseRuntimeMetadata":{
      "alertName":"Unexpected file access",
      "arguments":{
         "flags":[
            "O_RDONLY",
            "O_CLOEXEC"
         ],
         "path":"/lib/x86_64-linux-gnu/libcap.so.2.44"
      },
      "infectedPID":48570,
      "md5Hash":"09a0ed4979be0e0a380bac34cf0d6244",
      "sha1Hash":"432a5e7f53f880f14b52576e94ce9be607b72882",
      "severity":1,
      "size":"77 kB",
      "timestamp":"2025-04-25T17:58:11.161783251Z",
      "trace":{       
      }
   },
   "CloudMetadata":null,
   "RuleID":"R0002",
   "RuntimeK8sDetails":{
      "clusterName":"honeycluster",
      "containerName":"ping-app",
      "hostNetwork":false,
      "image":"ghcr.io/k8sstormcenter/webapp:latest",
      "imageDigest":"sha256:f4a78579cffad0fda06a554f11138d6dc28a5a97506edbf7b6f05413e4e3e084",
      "namespace":"default",
      "containerID":"a2f0834dd6b6a1b8444c420158e8b73c5345ac84eeb487701a3eb6537591e581",
      "podName":"webapp-765cc5d648-bb44n",
      "podNamespace":"default",
      "workloadName":"webapp",
      "workloadNamespace":"default",
      "workloadKind":"Deployment"
   },
   "RuntimeProcessDetails":{
      "processTree":{
         "pid":41204,
         "cmdline":"apache2 -DFOREGROUND",
         "comm":"apache2",
         "ppid":41129,
         "pcomm":"containerd-shim",
         "uid":0,
         "gid":0,
         "startTime":"0001-01-01T00:00:00Z",
         "cwd":"/var/www/html",
         "path":"/usr/sbin/apache2",
         "childrenMap":{
            "apache2␟41229":{
               "pid":41229,
               "cmdline":"apache2 -DFOREGROUND",
               "comm":"apache2",
               "ppid":41204,
               "pcomm":"apache2",
               "uid":33,
               "gid":33,
               "startTime":"0001-01-01T00:00:00Z",
               "cwd":"/var/www/html",
               "path":"/usr/sbin/apache2",
               "childrenMap":{
                  "sh␟48569":{
                     "pid":48569,
                     "cmdline":"/bin/sh -c ping -c 4 172.16.0.2",
                     "comm":"sh",
                     "ppid":41229,
                     "pcomm":"apache2",
                     "hardlink":"/bin/dash",
                     "uid":33,
                     "gid":33,
                     "startTime":"0001-01-01T00:00:00Z",
                     "upperLayer":false,
                     "cwd":"/var/www/html",
                     "path":"/bin/dash",
                     "childrenMap":{
                        "ping␟48570":{
                           "pid":48570,
                           "cmdline":"/bin/ping -c 4 172.16.0.2",
                           "comm":"ping",
                           "ppid":48569,
                           "pcomm":"sh",
                           "hardlink":"/bin/ping",
                           "uid":33,
                           "gid":33,
                           "startTime":"0001-01-01T00:00:00Z",
                           "upperLayer":false,
                           "cwd":"/var/www/html",
                           "path":"/bin/ping"
                        }
                     }
                  }
               }
            }
         }
      },
      "containerID":"a2f0834dd6b6a1b8444c420158e8b73c5345ac84eeb487701a3eb6537591e581"
   },
   "event":{
      "runtime":{
         "runtimeName":"containerd",
         "containerId":"a2f0834dd6b6a1b8444c420158e8b73c5345ac84eeb487701a3eb6537591e581",
         "containerName":"ping-app",
         "containerImageName":"ghcr.io/k8sstormcenter/webapp:latest",
         "containerImageDigest":"sha256:f4a78579cffad0fda06a554f11138d6dc28a5a97506edbf7b6f05413e4e3e084"
      },
      "k8s":{
         "namespace":"default",
         "podName":"webapp-765cc5d648-bb44n",
         "podLabels":{
            "app":"webapp",
            "pod-template-hash":"765cc5d648"
         },
         "containerName":"ping-app",
         "owner":{         
         }
      },
      "timestamp":1745603891161783251,
      "type":"normal"
   },
   "level":"error",
   "message":"Unexpected file access: /lib/x86_64-linux-gnu/libcap.so.2.44 with flags O_RDONLY,O_CLOEXEC",
   "msg":"Unexpected file access",
   "time":"2025-04-25T17:58:11Z"
}
```
```
bob.yaml
    - flags:
      - O_CLOEXEC
      - O_RDONLY
      path: /lib/x86_64-linux-gnu/libcap.so.2.44
```

### Diff 2 that should not be a diff

```json
{"BaseRuntimeMetadata":{"alertName":"Unexpected file access","arguments":{"flags":["O_RDONLY"],"path":"/var/www/html/ping.php"},"infectedPID":41229,"md5Hash":"4e79f11b07df8f72e945e0e3b3587177","sha1Hash":"b361a04dcb3086d0ecf960d3acaa776c62f03a55","severity":1,"size":"730 kB","timestamp":"2025-04-25T17:58:11.154208794Z","trace":{}},"CloudMetadata":null,"RuleID":"R0002","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"image":"ghcr.io/k8sstormcenter/webapp:latest","imageDigest":"sha256:f4a78579cffad0fda06a554f11138d6dc28a5a97506edbf7b6f05413e4e3e084","namespace":"default","containerID":"a2f0834dd6b6a1b8444c420158e8b73c5345ac84eeb487701a3eb6537591e581","podName":"webapp-765cc5d648-bb44n","podNamespace":"default","workloadName":"webapp","workloadNamespace":"default","workloadKind":"Deployment"},"RuntimeProcessDetails":{"processTree":{"pid":41204,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":41129,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","childrenMap":{"apache2␟41229":{"pid":41229,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":41204,"pcomm":"apache2","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2","childrenMap":{"sh␟48569":{"pid":48569,"cmdline":"/bin/sh -c ping -c 4 172.16.0.2","comm":"sh","ppid":41229,"pcomm":"apache2","hardlink":"/bin/dash","uid":33,"gid":33,"startTime":"0001-01-01T00:00:00Z","upperLayer":false,"cwd":"/var/www/html","path":"/bin/dash"}}}}},"containerID":"a2f0834dd6b6a1b8444c420158e8b73c5345ac84eeb487701a3eb6537591e581"},"event":{"runtime":{"runtimeName":"containerd","containerId":"a2f0834dd6b6a1b8444c420158e8b73c5345ac84eeb487701a3eb6537591e581","containerName":"ping-app","containerImageName":"ghcr.io/k8sstormcenter/webapp:latest","containerImageDigest":"sha256:f4a78579cffad0fda06a554f11138d6dc28a5a97506edbf7b6f05413e4e3e084"},"k8s":{"namespace":"default","podName":"webapp-765cc5d648-bb44n","podLabels":{"app":"webapp","pod-template-hash":"765cc5d648"},"containerName":"ping-app","owner":{}},"timestamp":1745603891154208794,"type":"normal"},"level":"error","message":"Unexpected file access: /var/www/html/ping.php with flags O_RDONLY","msg":"Unexpected file access","time":"2025-04-25T17:58:11Z"}
```


```
bob.yaml:
    - flags:
      - O_RDONLY
      path: /var/www/html/ping.php
```

