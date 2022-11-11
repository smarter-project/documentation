# Overview
This document will help you run a Smarter k3s server  

# Running on docker

## System requirements

### k3s cloud server 
* Local linux box, AWS EC2 VM instance or Google Cloud Platform GCE VM instance
* OS: Ubuntu 18.04 or later
* Architecture: aarch64 or amd64
* CPU: at least 1vcpu
* RAM: At least 3.75GB
* Storage: At least 10GB
* Multiple k3s cloud servers can be run in a single server if different server ports are used (HOSTPORT).

### EKS or equivalent
* A k8s equivalent cluster 

### dev machine
* User's desktop, capable of accessing cluster server IP and port

## Network topology
* The edge node needs to have access to cloud services provided by the k3s cloud 

### Firewall

Make sure you open the ports from the k3s cloud cluster that edge devices need to access. The k3s server port should also be open to enable control of the k3s server

## Setting k3s server up

[k3s](https://github.com/k3s-io/k3s) repository and [Rancher docker hub](https://hub.docker.com/r/rancher/k3s/) provide docker images and artifacts (k3s) allowing k3s to run as container.
This repository provides the file [k3s-cloud-start.sh](./scripts/k3s-cloud-start.sh) that automates that process and runs a k3s suitable to be a cloud k3s server
Execute the following command to download the file:
```
wget https://raw.githubusercontent.com/smarter-project/documentation/main/scripts/k3s-cloud-start.sh
```

A few options should be set on the script either by environment variables or editing the script.

execute the script:
```
./k3s-cloud-start.sh
```

The script will create another local script that can be used to restart k3s if necessary, the script is called `start_k3s_<instance name>.sh`.
The files `token.<instance name>` and `kube.<instance name>.config` contains the credentials to be use to authenticate a node (token file) or kubectl (kube.config file).
*NOTE*: Is is important K3S_VERSION on client matches the server otherwise things are likely not to work
The `k3s-start.sh` downloads a compatible k3s executable (that can replace kubectl) with the server and also creates a `kubectl-<instance name>.sh` script that emulates a kubectl with the correct credentials.
The file `env-<instance name>.sh` creates an alias for kubectl and adds the KUBECONFIG enviroment variable. 

# Joining a k3s node
To join an node to the cloud cluster, the `kube_cloud_install-<instance name>.sh` to the node and execute it. The script is already configured to connect to the server `<instance name>`.  
