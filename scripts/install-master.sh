#!/bin/bash

sed --in-place '/~\/kube-setup\/scripts\/install-kube-master.sh/d' ~/.bashrc
echo "~/kube-setup/scripts/install-kube-master.sh" >> ~/.bashrc

sudo apt update

# Install utilities
sudo apt install -y bmon 

# Network set up, set up packet passthrough
./setup-networking.sh

# DHCP Server install and initialise
./install-dhcp-server.sh

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
# use 64 bit kernel
echo "arm_64bit=1" | sudo tee -a /boot/config.txt

# Disk optimisations - move temp to ram.
# Reduce writes to the SD Card and increase IO performance by mapping the /tmp and /var/log directories to RAM. 
# Note you will lose the contents of these directories on reboot.
echo "tmpfs /tmp  tmpfs defaults,noatime 0 0" | sudo tee -a /etc/fstab && \
echo "tmpfs /var/log  tmpfs defaults,noatime,size=30m 0 0" | sudo tee -a /etc/fstab

# enable cgroups for Kubernetes
sudo sed -i 's/$/ ipv6.disable=1 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt

# Install Docker
curl -sSL get.docker.com | sh && sudo usermod $USER -aG docker

# perform system upgrade
sudo apt update && sudo apt dist-upgrade -y

# Rename your pi
echo -e "\nYour Raspberry Pi/Kubernetes Master has been renamed 'k8smaster'\n"
echo -e "Remember to use system name when reconnecting  pi@k8smaster.local\n"
sudo raspi-config nonint do_hostname 'k8smaster'

sudo reboot