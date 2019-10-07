#!/bin/bash

# Rename your pi
read -p "Name your Raspberry Pi (eg k8smaster, k8snode1, ...): " RPINAME
sudo raspi-config nonint do_hostname $RPINAME

# Update aptitude
sudo apt update 
sudo apt install bmon 

# Network set up, set up packet passthrough
./networking.sh

# DHCP Server install and initialise
./dhcp-server.sh

# Set iptables in legacy mode - required for Kube compatibility
# https://github.com/kubernetes/kubernetes/issues/71305
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

#disable swap
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo systemctl disable dphys-swapfile

# maximise memory by reducing gpu memory
echo "gpu_mem=16" | sudo tee -a /boot/config.txt

# enable cgroups for Kubernetes
sudo sed -i 's/$/ ipv6.disable=1 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt

# Install Docker
curl -sSL get.docker.com | sh && sudo usermod $USER -aG docker

# Install Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -q
sudo apt-get install -qy kubeadm

# Preload the Kubernetes images
kubeadm config images pull

# Set up Kubernetes Master Node
sudo kubeadm init --apiserver-advertise-address=192.168.100.1 --pod-network-cidr=10.244.0.0/16 --token-ttl 0

# make kubectl generally avaiable
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel
sudo sysctl net.bridge.bridge-nf-call-iptables=1
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

sudo reboot