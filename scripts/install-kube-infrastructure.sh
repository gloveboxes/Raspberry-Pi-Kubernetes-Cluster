#!/bin/bash


sleep 10

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