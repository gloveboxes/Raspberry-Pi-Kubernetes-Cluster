#!/bin/bash

docker --version
        

# Install Kubernetes
while : ;
do
    echo -e "\nInstalling Kubernetes apt key\n"
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    if [ $? -eq 0 ]
    then
        break
    else
        echo -e "\nGet Kuberetes key failed. Check internet connection. Retrying in 10 seconds.\n"
        sleep 10
    fi
done

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

while : ;
do
    echo -e "\nInstalling Kubernetes Packages\n"
    sudo apt-get update && sudo apt-get install -y kubeadm
    if [ $? -eq 0 ]
    then
        break
    else
        echo -e "\nKubernetes installation failed. Check internet connection. Retrying in 10 seconds.\n"
        sleep 10
    fi
done