#!/bin/bash

# Enable IP V4 Packet Routing
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p

# Ethernet static IP
echo 'interface eth0' | sudo tee -a /etc/dhcpcd.conf
echo 'static ip_address=192.168.100.1/24' | sudo tee -a /etc/dhcpcd.conf
echo 'noipv6' | sudo tee -a /etc/dhcpcd.conf

# stop and restart eth0 network interface
sudo ip link set eth0 down && sudo ip link set eth0 up 
sleep 10

# enable Ethernet to WiFi traffic routing
sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o wlan0 -j MASQUERADE
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
sudo sed -i -e '$i \iptables-restore < /etc/iptables.ipv4.nat\n' /etc/rc.local

# Disable WiFi power management
sudo sed -i -e '$i \iwconfig wlan0 power off\n' /etc/rc.local
sudo iwconfig wlan0 power off
