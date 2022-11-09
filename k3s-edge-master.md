# Overview
This document will help you run a Smarter k3s master  

# Running on docker

## System requirements

### k3s edge master
* Local linux box, AWS EC2 VM instance or Google Cloud Platform GCE VM instance
* OS: Ubuntu 18.04
* Architecture: amd64
* CPU: at least 1vcpu
* RAM: At least 3.75GB
* Storage: At least 10GB

### k3s edge master
* Local linux (x86_64 or arm64)/windows/MacOS machine with docker, AWS EC2 VM instance or Google Cloud Platform GCE VM instance
* Multiple k3s edge masters can be run in a single server if different server ports are used (HOSTPORT).

### dev machine
* User's desktop, capable of ssh'ing to the k3s edge master host, it also can be k3s edge master

## Network topology
* The k3s master host and the dev machine both need access to the Internet.
* The dev machine needs to be able to `ssh` and `scp` into the k3s master host.
* The k3s master needs to have port 6443 (or the port that is desired to run k3s on) open for k3s.
* The edge node needs to have access to port 6443 (or the port that is desired to run k3s on) in the k3s master.

### Firewall

Make sure you open port 6443 or the port used in your instance installation in your firewall so external hosts can contact your new master.
On AWS, you will need to do this by editing the security group policy and adding an inbound rule.

## Setting k3s master up

[k3s](https://github.com/k3s-io/k3s) repository and [Rancher docker hub](https://hub.docker.com/r/rancher/k3s/) provide docker images and artifacts (k3s) allowing k3s to run as container.
This repository provides the file [k3s-start.sh](https://gitlab.com/smarter-project/documentation.git/public/scripts/k3s-start.sh) that automates that process and runs a k3s suitable to be a SMARTER k3s master
Execute the following command to download the file:
```
wget https://gitlab.com/smarter-project/documentation.git/public/scripts/k3s-start.sh
```

A few options should be set on the script either by environment variables or editing the script.

execute the script:
```
./k3s-start.sh
```

The script will create another local script that can be used to restart k3s if necessary, the script is called start_k3s_\<instance name\>.sh.
The files token.\<instance name\> and kube.\<instance name\>.config contains the credentials to be use to authenticate a node (token file) or kubectl (kube.config file).
*NOTE*: Is is important K3S_VERSION on client matches the server otherwise things are likely not to work
The k3s-start.sh downloads a compatible k3s executable (that can replace kubectl) with the server and also creates a kubectl-\<instance name\>.sh script that emulates a kubectl with the correct credentials.
The file env-<instance name>.sh create an alias for kubectl and adds the KUBECONFIG enviroment variable. 

# Joining a non-yocto k3s node
To join an node which does not use our yocto build. Copy the kube_edge_install-\<instance name\>.sh to the node and execute it. The script is already configured to connect to the server \<instance name\>.  
