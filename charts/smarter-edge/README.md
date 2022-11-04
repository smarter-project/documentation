# smarter-edge

This chart deploys all the edge components and infrastructure for SMARTER including
cni, dns and smarter-device-manager and creates a single lable that installs a pod for each in a node, smarter-edge=enabled.


For more information on smarter go to https://getsmarter.io

## TL;DR

```console
helm repo add smarter https://smarter-project.gitlab.io/documentation/charts
helm install my-smarter-edge smarter-edge
```

# Overview


# Prerequisites

This chart assumes a full deployment of k3s with traefik, etc.

* k3s 1.25+
* Helm 3.2.0+

# Uninstalling the Chart

```
$ helm delete my-smarter-edge
```

# Parameters
