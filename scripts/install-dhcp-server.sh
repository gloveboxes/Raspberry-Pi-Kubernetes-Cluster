#!/bin/bash

echo -e "\nInstalling and configuring DHCP Server\n"

# Install DHCP Server
sudo apt-get install -y -qq isc-dhcp-server >/dev/null
sudo service isc-dhcp-server stop

# bind IPV4 to eth0
sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="eth0"/g' /etc/default/isc-dhcp-server
sudo sed -i 's/INTERFACESv6=""/INTERFACESv4="eth0"/g' /etc/default/isc-dhcp-server

# Append required dhcp config to system config
cat dhcpd.conf | sudo tee -a /etc/dhcp/dhcpd.conf

echo -e "\nStarting DHCP Server\n"

sudo service isc-dhcp-server start
