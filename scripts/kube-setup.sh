#!/bin/bash

# Rename your pi
read -p "Name your Raspberry Pi (eg k8smaster, k8snode1, ...): " RPINAME
sudo raspi-config nonint do_hostname $RPINAME

# Update aptitude
sudo apt update 
sudo apt install -y bmon 

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

echo "The system reboot. Then run ~/kube-setup/scripts/kube-master.sh"
sudo reboot