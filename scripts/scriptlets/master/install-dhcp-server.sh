#!/bin/bash

sudo service isc-dhcp-server stop

# bind IPV4 to eth0
sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="eth0"/g' /etc/default/isc-dhcp-server > /dev/null
# https://www.raspberrypi.org/forums/viewtopic.php?t=210310
# sudo sed -i 's/INTERFACESv6=""/INTERFACESv6="eth0"/g' /etc/default/isc-dhcp-server > /dev/null

# Append required dhcp config to system config
cat ~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/master/dhcpd.conf | sudo tee -a /etc/dhcp/dhcpd.conf > /dev/null

echo -e "\nStarting DHCP Server\n"

sudo service isc-dhcp-server start
