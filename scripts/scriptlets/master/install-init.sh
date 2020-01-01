#!/bin/bash

while :
do
    echo -e "Updating OS and Installing Utilities"
    sudo apt-get update && sudo apt-get install -y bmon sshpass isc-dhcp-server nfs-kernel-server && sudo apt-get upgrade -y 
    if [ $? -eq 0 ]
    then
        break
    else
        echo -e "\nUpdate failed. Retrying system update in 10 seconds\n"
        sleep 10
    fi
done

echo -e "\nSetting iptables to legacy mode - patch required for Kubernetes on Debian 10\n"
# Set iptables in legacy mode - required for Kube compatibility
# https://github.com/kubernetes/kubernetes/issues/71305
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy > /dev/null
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy > /dev/null

echo -e "\nDiabling Linux swap file - Required for Kubernetes\n"
#disable swap
sudo dphys-swapfile swapoff > /dev/null
sudo dphys-swapfile uninstall > /dev/null
sudo systemctl disable dphys-swapfile > /dev/null

# Setting GPU Memory to minimum - 16MB
echo "gpu_mem=16" | sudo tee -a /boot/config.txt > /dev/null

# Enable I2C
sudo raspi-config nonint do_i2c 0
# Enable SPI
sudo raspi-config nonint do_spi 0

# Disable hdmi to reduce power consumption
sudo sed -i -e '$i \/usr/bin/tvservice -o\n' /etc/rc.local

echo -e "\nMoving /tmp and /var/log to tmpfs - reduce SD Card wear\n"
# Disk optimisations - move temp to ram.
# Reduce writes to the SD Card and increase IO performance by mapping the /tmp and /var/log directories to RAM. 
# Note you will lose the contents of these directories on reboot.

# Replaced with log2ram

# echo "tmpfs /tmp  tmpfs defaults,noatime 0 0" | sudo tee -a /etc/fstab > /dev/null
# echo "tmpfs /var/log  tmpfs defaults,noatime,size=30m 0 0" | sudo tee -a /etc/fstab > /dev/null

echo -e "\nEnabling cgroup support for Kubernetes\n"
# enable cgroups for Kubernetes
sudo sed -i 's/$/ ipv6.disable=1 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt

echo -e "\nRenamed the Raspberry Pi Kubernetes Master to k8smaster.local\n"
sudo raspi-config nonint do_hostname 'k8smaster'

sudo reboot