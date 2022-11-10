# Overview
This document will help you run a Smarter k3s server  

# Running on docker

## System requirements

### k3s edge server
* Local linux box, AWS EC2 VM instance or Google Cloud Platform GCE VM instance
* OS: Ubuntu 18.04 or later
* Architecture: amd64
* CPU: at least 1vcpu
* RAM: At least 3.75GB
* Storage: At least 10GB

### k3s edge server
* Local linux (x86_64 or arm64)/windows/MacOS machine with docker, AWS EC2 VM instance or Google Cloud Platform GCE VM instance
* Multiple k3s edge servers can be run in a single server if different server ports are used (HOSTPORT).

### dev machine
* User's desktop, capable of ssh'ing to the k3s edge server host, it also can be k3s edge server

## Network topology
* The k3s server host and the dev machine both need access to the Internet.
* The dev machine needs to be able to `ssh` and `scp` into the k3s server host.
* The k3s server needs to have port 6443 (or the port that is desired to run k3s on) open for k3s.
* The edge node needs to have access to port 6443 (or the port that is desired to run k3s on) in the k3s server.

### Firewall

Make sure you open port 6443 or the port used in your instance installation in your firewall so external hosts can contact your new server.
On AWS, you will need to do this by editing the security group policy and adding an inbound rule.

## Setting k3s server up

[k3s](https://github.com/k3s-io/k3s) repository and [Rancher docker hub](https://hub.docker.com/r/rancher/k3s/) provide docker images and artifacts (k3s) allowing k3s to run as container.
This repository provides the file [k3s-start.sh](./scripts/k3s-start.sh) that automates that process and runs a k3s suitable to be a SMARTER k3s server
Execute the following command to download the file:
```
wget https://raw.githubusercontent.com/smarter-project/documentation/main/scripts/k3s-start.sh
```

A few options should be set on the script either by environment variables or editing the script.

execute the script:
```bash
./k3s-start.sh
```

The script will create another local script that can be used to restart k3s if necessary, the script is called `start_k3s_<instance name>.sh`.
The files `token.<instance name>` and `kube.<instance name>.config` contains the credentials to be use to authenticate a node (token file) or kubectl (kube.config file).
*NOTE*: Is is important K3S_VERSION on client matches the server otherwise things are likely not to work
The `k3s-start.sh` downloads a compatible k3s executable (that can replace kubectl) with the server and also creates a `kubectl-<instance name>.sh` script that emulates a kubectl with the correct credentials.
The file `env-<instance name>.sh` create an alias for kubectl and adds the KUBECONFIG enviroment variable. 

# Joining a k3s edge node to the cluster
The following instructions describe how to setup a node for our demo.

## Setup your edge nodes and join the edge cluster
Plugin USB camera. You should be able to see the camera at `/dev/videoX`. Take note of which video device the camera is attached to. Most likely it will be `/dev/video0` or `/dev/video1`.

On the rpi4 with **Ubuntu**, you must also append the text `cgroup_memory=1 cgroup_enable=memory` to the file:
```
- `/boot/firmware/nobtcmd.txt` if Ubuntu 19.10
- `/boot/firmware/cmdline.txt` if Ubuntu 20.04
```

On the rpi4 with **64 bit Raspbian**, you must also append the text `cgroup_memory=1 cgroup_enable=memory` to the file:
```
- `/boot/cmdline.txt`
```

Then reboot the system.

If you are running on a **Xavier**, **Xavier NX**, or a **Nano**, open the file `/etc/docker/daemon.json` on the device and ensure that the default runtime is set to nvidia. The file should look as follows:
```bash
{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
```
To join an node to the edge cluster, copy the `kube_edge_install-<instance name>.sh` script generated from the step above to the node and execute it by simply running:
```bash
./kube_edge_install-<instance name>.sh
```
The script is already configured to connect to the server `<instance name>`. At this point your node will be registered to the cluster, but awaiting the deployment of the base smarter edge infrastructure elements.
