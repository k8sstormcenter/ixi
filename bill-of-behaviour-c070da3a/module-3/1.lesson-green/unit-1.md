---
kind: unit

title: Consume the app on client cluster

name: consume-app-install
---
__THIS PART WILL SHOW HOW KUBESCAPE WORKS FOR THE CUSTOMER DURING BOBTEST__
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
WIP: DO NOT EXECUTE THIS LINE

```sh
bobctl install webapp
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

We ll wait until we have an application profile again and we ll throw it away, this is not required if you use
exactly the same everything on this kubernetes as you did as the vendor. I.e. if the `template-hash` matches you
dont need to delete it.


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

now edit that profile (so it keeps its name), but use the content of the one from Module 1!!!

```
python3 bob.py 
```

which is the equivalent to manually substituting and patching

```sh   
echo $rs
envsubst < /home/laborant/honeycluster/traces/kubescape-verify/attacks/webapp/bob_applicationprofile_restart.yaml > /home/laborant/honeycluster/traces/kubescape-verify/attacks/webapp/bob_restart.yaml
```

`patch` the ping-profile: (this may or may not be necessary)
```sh
kubectl delete applicationprofile replicaset-$rs
```

```sh
kubectl apply -f /home/laborant/honeycluster/traces/kubescape-verify/attacks/webapp/bob_restart.yaml
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


## 6 watch how k3s is different from k8s BOB-MERGE

We are still simulating the `benign traffic` using the loop TODO C : use the bob-test deployment instead. Its already in git.

We already see one interesting log and
notice that there is one `syscall` different between `k8s` and `k3s`, which is the `gettid`.






## 7 Discuss what happens if the profile is missing the shutdown


Open a third terminal and:

```
kubectl logs -n honey -l app=node-agent --tail=-1 -f
```
back in another terminal:

```
export pod=$(kubectl get pod -n default -o jsonpath='{.items[0].metadata.name}')
kubectl get pod $pod
```
```sh
kubectl delete pod $pod
```
switch to the tab of the logs

again it is rerecording the profile again

```json
{"level":"info","ts":"2025-04-25T20:24:06Z","msg":"start monitor on container","container ID":"6f95b220e4e1b06b391c98409682064cf7e9115286792f139c6ca52221a23b85","k8s workload":"default/webapp-8b697d7f9-hxz4v/ping-app","ContainerImageDigest":"sha256:efbbeae81bb8af21288cdda8f0f3de900b73dad19b380937b7374965ee41957f","ContainerImageName":"ghcr.io/k8sstormcenter/webapp:latest"}
{"level":"info","ts":"2025-04-25T20:24:07Z","msg":"stop monitor on container - container has terminated","container ID":"c0cbad967bf756dce1a6716bd39b20250b218a1dfee594c024ab883ad40ab576","k8s workload":"default/webapp-8b697d7f9-wr5s8/ping-app"}
```

what we see is that we didnt do a `rollout restart`, but a `pod delete`

```json
{"BaseRuntimeMetadata":{"alertName":"Unexpected system call","arguments":{"syscall":"gettid"},"infectedPID":4183,"md5Hash":"4e79f11b07df8f72e945e0e3b3587177","sha1Hash":"b361a04dcb3086d0ecf960d3acaa776c62f03a55","severity":1,"size":"730 kB","timestamp":"2025-04-25T20:21:33.310968529Z","trace":{}},"CloudMetadata":null,"RuleID":"R0003","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"namespace":"default","containerID":"c0cbad967bf756dce1a6716bd39b20250b218a1dfee594c024ab883ad40ab576","podName":"webapp-8b697d7f9-wr5s8","podNamespace":"default","workloadName":"webapp","workloadNamespace":"default","workloadKind":"Deployment"},"RuntimeProcessDetails":{"processTree":{"pid":4183,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":3927,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},"containerID":"c0cbad967bf756dce1a6716bd39b20250b218a1dfee594c024ab883ad40ab576"},"event":{"runtime":{"runtimeName":"containerd","containerId":"c0cbad967bf756dce1a6716bd39b20250b218a1dfee594c024ab883ad40ab576"},"k8s":{"node":"node-01","namespace":"default","podName":"webapp-8b697d7f9-wr5s8","podLabels":{"app":"webapp","pod-template-hash":"8b697d7f9"},"containerName":"ping-app","owner":{}},"timestamp":1745612493310968529,"type":"normal"},"level":"error","message":"Unexpected system call: gettid","msg":"Unexpected system call","time":"2025-04-25T20:21:33Z"}
{"BaseRuntimeMetadata":{"alertName":"Unexpected system call","arguments":{"syscall":"tkill"},"infectedPID":4183,"md5Hash":"4e79f11b07df8f72e945e0e3b3587177","sha1Hash":"b361a04dcb3086d0ecf960d3acaa776c62f03a55","severity":1,"size":"730 kB","timestamp":"2025-04-25T20:21:33.313413767Z","trace":{}},"CloudMetadata":null,"RuleID":"R0003","RuntimeK8sDetails":{"clusterName":"honeycluster","containerName":"ping-app","hostNetwork":false,"namespace":"default","containerID":"c0cbad967bf756dce1a6716bd39b20250b218a1dfee594c024ab883ad40ab576","podName":"webapp-8b697d7f9-wr5s8","podNamespace":"default","workloadName":"webapp","workloadNamespace":"default","workloadKind":"Deployment"},"RuntimeProcessDetails":{"processTree":{"pid":4183,"cmdline":"apache2 -DFOREGROUND","comm":"apache2","ppid":3927,"pcomm":"containerd-shim","uid":0,"gid":0,"startTime":"0001-01-01T00:00:00Z","cwd":"/var/www/html","path":"/usr/sbin/apache2"},"containerID":"c0cbad967bf756dce1a6716bd39b20250b218a1dfee594c024ab883ad40ab576"},"event":{"runtime":{"runtimeName":"containerd","containerId":"c0cbad967bf756dce1a6716bd39b20250b218a1dfee594c024ab883ad40ab576"},"k8s":{"node":"node-01","namespace":"default","podName":"webapp-8b697d7f9-wr5s8","podLabels":{"app":"webapp","pod-template-hash":"8b697d7f9"},"containerName":"ping-app","owner":{}},"timestamp":1745612493313413767,"type":"normal"},"level":"error","message":"Unexpected system call: tkill","msg":"Unexpected system call","time":"2025-04-25T20:21:33Z"}
```

But, we again these are just events related to the `delete` action.
