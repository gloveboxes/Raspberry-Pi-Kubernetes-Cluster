#!/bin/bash

echo -e "\nInstalling Kubernetes\n"

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

echo -e "\nYou will need to make a note of the Kubernetes kubeadm join token displayed as part of the initialisation process:)\n"

# make kubectl generally avaiable
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


cd ~/Raspberry-Pi-Kubernetes-Cluster-master/kubesetup

echo -e "\nInstalling Flannel\n"

# Install Flannel
echo -e "\n\nInstalling Flannel CNI\n"
sudo sysctl net.bridge.bridge-nf-call-iptables=1
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

# Install MetalLB LoadBalancer
# https://metallb.universe.tf
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml
kubectl apply -f ./metallb/metallb.yml

echo -e "\nInstalling MetalLB LoadBalancer\n"

# Install Kubernetes Dashboard
# https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
# https://medium.com/@kanrangsan/creating-admin-user-to-access-kubernetes-dashboard-723d6c9764e4
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml
kubectl apply -f ./dashboard/dashboard-admin-user.yml
kubectl apply -f ./dashboard/dashboard-admin-role-binding.yml

echo -e "\nInstalling Persistent Storage Support\n"

## Enable Persistent Storage
kubectl apply -f ./persistent-storage/nfs-client-deployment-arm.yaml
kubectl apply -f ./persistent-storage/storage-class.yaml
kubectl apply -f ./persistent-storage/persistent-volume.yaml
kubectl apply -f ./persistent-storage/persistent-volume-claim.yaml
kubectl apply -f ./persistent-storage/nginx-test-pod.yaml

## Remove install restart after reboot
sed --in-place '/~\/Raspberry-Pi-Kubernetes-Cluster-master\/scripts\/install-kube-master.sh/d' ~/.bashrc

echo -e "\nMake a note of the kubeadm join and token displayed above. \nYou will need for joing Kubernettes nodes to this master."
echo -e "\n\nUseful Commands:"
echo -e "\nwatch kubectl get pods --namespace=kube-system -o wide"
echo -e "\nkubectl get pods --namespace=metallb-system -o wide"

sudo reboot