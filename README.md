# SMARTER Demo Deployment Instructions

[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/smarter)](https://artifacthub.io/packages/search?repo=smarter)
## This demo makes the following assumptions about your environment

In this guide we assume you have done the following:
- You should have an installed InfluxDB and Grafana instance in a separate kubernetes cluster (cloud or local).
    - these may be installed on a second cloud node, with its own k3s server, we will refer to this as the cloud-data-node
    - if you don't have a cloud-data-node, you can follow [these instructions](./k3s-cloud-server.md)
- You should have a cloud-based k3s server dedicated for edge deployment (we will refer to this as k3s-edge-server) before proceeding any further
    - if you don't have a k3s-edge-server, you can follow [these instructions](./k3s-edge-server.md)
- You will also need an installed k3s edge node which has already been setup to talk to k3s-edge-server
    - instructions for registering a node running a **64 bit kernel and user space** are available [here](./k3s-edge-server.md#Joining a k3s edge node to the cluster)

**Hardware:** 
- Rpi4 4GB running any debian based OS or Xavier AGX 16GB running L4T 32.4.3 provided by the jetpack 4.4 release. Others have demonstrated this stack working on Nvidia Nano and Nvidia Xavier NX, but our team does not test on these platforms. Any Arm based device running a **64 bit kernel and user space** should work.
- PS3 Eye Camera (or Linux compatible web cam with audio) serving both audio and video data (other USB cameras with microphones may work). Microphone **MUST** support 16KHz sampling rate.
- A development machine (your work machine) setup to issue kubectl commands to your edge k3s cluster
- (optional) PMS7003 Air Quality Sensor connected over Serial USB to USB port
- (optional) Weather:bit connected over Serial USB to USB port

**Software:**
- Dev machine running kubectl client 1.25
- git, curl must also be installed
- K3s server version 1.25

**Connectivity:**
- You must be able to reach your edge node via IP on ports `22`(ssh) and `2520`(Webserver) from your dev machine for parts of this demo to work 
- The node must be able to reach your k3s-edge-server and cloud-data-node via IP

## Deploy demo

### Deploy using terraform

If you have an AWS account, a terraform script is available on this repository at [Terraform readme](terraform/README.md). This script will allocate an AWS EC2 Graviton instance, install k3s and helm and install all the charts needed to run this demo. The only missing part is one or more edge nodes that the user needs to provide.

### Step by step deployment

- To deploy the base system components common to all edge nodes, as well as the demo applications, we opt to use **Helm v3**. To install helm on the device which you are managing your k3s edge cluster with, you can follow the guide [here](https://helm.sh/docs/intro/install/#from-script).
- Ensure in your environment that your kubeconfig is set properly. As a quick sanity check you can run:
  ```bash
  kubectl cluster-info
  ```
  and you should get a message: `Kubernetes control plane is running at https://<k3s edge server ip>:<k3s edge server port`
- Tell helm to add the smarter repo, such that you can deploy our charts:
  ```bash
  helm repo add smarter https://smarter-project.github.io/documentation
  ```
- Use the helm chart on https://github.com/smarter-project/documentation/chart to install CNI, DNS and device-manager. This can be done by 
  ```bash
  helm install my-smarter-edge smarter/smarter-edge --wait
  ```
- With the smarter-edge chart installed, you can verify that all the base pods are ready by running:
  ```bash
  kubectl get pods -A -o wide
  ```
- Now we deploy our demo by first applying the helm chart for the demo:
  ```bash
  helm install my-smarter-demo smarter/smarter-demo --namespace smarter --create-namespace
  ```
- At this point applications will be installed into the cluster, but no pods will come up as running, as the nodes rely on node labels to be set for the application pods to run.
- Label you nodes by running the following:
  ```bash
  export NODE_NAME=<your node name>
  kubectl label node $NODE_NAME smarter-fluent-bit=enabled
  kubectl label node $NODE_NAME smarter-gstreamer=enabled
  kubectl label node $NODE_NAME smarter-pulseaudio=enabled
  kubectl label node $NODE_NAME smarter-inference=enabled
  kubectl label node $NODE_NAME smarter-image-detector=enabled
  kubectl label node $NODE_NAME smarter-audio-client=enabled
  ```
- At this point all on your target node you should see each of the above workloads running once the node has pulled down the images. You can monitor your cluster as each pod becomes ready by running:
  ```bash
  kubectl get pods -A -w
  ```
- With all nodes running successfully, if you are on the same network as your edge node, you can navigate a browser to the IP of the edge node, and see the image detector running on your camera feed in real time.
- To terminate the demo, you can simply unlabel the node for each workload:
  ```bash
  export NODE_NAME=<your node name>
  kubectl label node $NODE_NAME smarter-fluent-bit-
  kubectl label node $NODE_NAME smarter-gstreamer-
  kubectl label node $NODE_NAME smarter-pulseaudio-
  kubectl label node $NODE_NAME smarter-inference-
  kubectl label node $NODE_NAME smarter-image-detector-
  kubectl label node $NODE_NAME smarter-audio-client-
  ```

