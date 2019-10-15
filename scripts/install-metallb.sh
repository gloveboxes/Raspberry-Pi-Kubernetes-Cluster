#!/bin/bash

# Install MetalLB LoadBalancer
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml
kubectl apply -f ../kubesetup/metallb/metallb.yml