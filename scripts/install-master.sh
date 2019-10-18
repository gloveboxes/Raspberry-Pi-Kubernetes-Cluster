#!/bin/bash

sed --in-place '/~\/Raspberry-Pi-Kubernetes-Cluster-master\/scripts\/install-kube-master.sh/d' ~/.bashrc
echo "~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/install-kube-master.sh" >> ~/.bashrc

sudo apt update

# Install utilities
sudo apt install -y bmon 

# Network set up, set up packet passthrough
./setup-networking.sh

# DHCP Server install and initialise
./install-dhcp-server.sh

echo -e "\nSetting iptables to legacy more - patch required for Kubernetes on Debian 10\n"

# Set iptables in legacy mode - required for Kube compatibility
# https://github.com/kubernetes/kubernetes/issues/71305
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

echo -e "\nDiabling Linux swap file - Required for Kubernetes\n"

#disable swap
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo systemctl disable dphys-swapfile

echo -e "\nReduing GPU Memory to minimum - 16MB\n"

# maximise memory by reducing gpu memory
echo "gpu_mem=16" | sudo tee -a /boot/config.txt

echo -e "\nEnabling 64 Bit Linux Kernel\n"
# use 64 bit kernel
echo "arm_64bit=1" | sudo tee -a /boot/config.txt

echo -e "\nMoving /tmp and /var/log to tmpfs - reduce SD Card wear\n"

# Disk optimisations - move temp to ram.
# Reduce writes to the SD Card and increase IO performance by mapping the /tmp and /var/log directories to RAM. 
# Note you will lose the contents of these directories on reboot.
echo "tmpfs /tmp  tmpfs defaults,noatime 0 0" | sudo tee -a /etc/fstab && \
echo "tmpfs /var/log  tmpfs defaults,noatime,size=30m 0 0" | sudo tee -a /etc/fstab

echo -e "\nEnabling cgroup support for Kubernetes\n"
# enable cgroups for Kubernetes
sudo sed -i 's/$/ ipv6.disable=1 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt

echo -e "\nInstall Docker\n"
# Install Docker
curl -sSL get.docker.com | sh && sudo usermod $USER -aG docker

echo -e "\nUpdating Operating System\n"
# perform system upgrade
sudo apt dist-upgrade -y

# Rename your pi
echo -e "\nYour Raspberry Pi/Kubernetes Master has been renamed 'k8smaster'\n"
echo -e "Remember to use system name when reconnecting  pi@k8smaster.local\n"
sudo raspi-config nonint do_hostname 'k8smaster'

sudo reboot