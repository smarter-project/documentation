# smarter-edge-demo

This chart deploys example edge demo components.

For more information on smarter go to https://getsmarter.io

## TL;DR

```console
helm install --set domain=example.com demo charts/demo
```

# Overview

The SMARTER demo is a collection of applications to read sensors, process them
(sometimes using ML inference) and ship results via MQTT to fluent-bit which 
sends them to the cloud for visualization/storage.

You must specify your smarter-cloud domain for this to work properly.  

This chart is meant to be a component of an umbrella chart which installs 
other dependencies.  It requires the smarter-cloud to be deployed on cloud
kubernetes instance and you must also deploy the smarter-edge helm chart on the
edge kubernetes instance.

# Prerequisites

This chart assumes a full deployment of k3s with traefik, etc.

* k3s 1.25+
* Helm 3.2.0+

# Uninstalling the Chart

```
$ helm delete demo
```

# Parameters

## Common parameters

| Name | Description | Value |
| ---- | ----------- | ----- |
| domain | Wildcard reverse proxy domain | example.com |

# Notes

- Make sure you set both the common parameters for things to work properly.