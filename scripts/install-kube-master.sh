#!/bin/bash

# Install Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -q
sudo apt-get install -qy kubeadm

# Preload the Kubernetes images
echo -e "\nPulling Kubernetes Images - this will take a few minutes depending on network speed.\n"
kubeadm config images pull

# Set up Kubernetes Master Node
sudo kubeadm init --apiserver-advertise-address=192.168.100.1 --pod-network-cidr=10.244.0.0/16 --token-ttl 0

# make kubectl generally avaiable
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel
echo -e "\n\nInstalling Flannel CNI\n"
sudo sysctl net.bridge.bridge-nf-call-iptables=1
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

./install-pods.sh

## Remove install restart after reboot
sed --in-place '/~\/kube-setup\/scripts\/install-kube-master.sh/d' ~/.bashrc