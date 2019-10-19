#!/bin/bash

echo -e "\nInstalling Kubernetes\n"

# let the system settle before kicking off kube install
sleep 10

# Install Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update -q
sudo apt-get install -qy kubeadm

# Preload the Kubernetes images
echo -e "\nPulling Kubernetes Images - this will take a few minutes depending on network speed.\n"
kubeadm config images pull


echo -e "\nInitialising Kubernetes Master - This will take a few minutes. Be patient:)\n"
echo -e "\nYou will need to make a note of the Kubernetes kubeadm join token displayed as part of the initialisation process:)\n"

# Set up Kubernetes Master Node
sudo kubeadm init --apiserver-advertise-address=192.168.100.1 --pod-network-cidr=10.244.0.0/16 --token-ttl 0

# make kubectl generally avaiable
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


## Remove install restart after reboot
sed --in-place '/~\/Raspberry-Pi-Kubernetes-Cluster-master\/scripts\/install-kube-master.sh/d' ~/.bashrc

echo -e "\nYou will need to make a note of the Kubernetes kubeadm join token displayed as part of the initialisation process:)\n"
echo -e "\n\nUseful Commands:"
echo -e "\nwatch kubectl get pods --namespace=kube-system -o wide"
echo -e "\nkubectl get pods --namespace=metallb-system -o wide"

sudo reboot