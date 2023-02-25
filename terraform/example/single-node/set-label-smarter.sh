#!/bin/bash
#
kubectl label node raspberrypi4 $(kubectl get ds -n smarter | cut -c 96-126 | grep smarter-)
