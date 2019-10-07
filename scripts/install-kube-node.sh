#!/bin/bash

# Install Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -q
sudo apt-get install -qy kubeadm

# Preload the Kubernetes images
echo -e "\nPulling Kubernetes Images - this will take a few minutes depending on network speed.\n"
kubeadm config images pull

## Remove install restart after reboot
sed --in-place '/~\/kube-setup\/scripts\/install-kube-node.sh/d' ~/.bashrc
