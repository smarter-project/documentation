# smarter-cloud

This chart deploys all the cloud-side components and infrastructure for SMARTER including
influxdb, grafana, prometheus, and fluent-bit which channels data from the edge to the
database for visualization.

It uses let's encrypt to setup SSL, so you need to set both the domain and your email
when you install the chart.  If you don't have your own domain, you can use nip.io as
the wildcard for the reverse proxy to use with SSL.

For more information on smarter go to https://getsmarter.io

## TL;DR

```console
helm install --set domain=example.com --set email=youremail@mail.com smarter-cloud charts/smarter-cloud
```

# Overview


# Prerequisites

This chart assumes a full deployment of k3s with traefik, etc.

* k3s 1.25+
* Helm 3.2.0+

# Uninstalling the Chart

```
$ helm delete my-smarter-cloud
```

# Parameters

## Common parameters

| Name | Description | Value |
| ---- | ----------- | ----- |
| email | Email to use for let's encrypt | NO DEFAULT |
| domain | Wildcard reverse proxy domain | example.com |

# Notes

- Make sure you set both the common parameters for things to work properly.
- If you use Cloudflare for DNS reverse proxy, make sure you do DNS only, it will mess with SSL certificates
