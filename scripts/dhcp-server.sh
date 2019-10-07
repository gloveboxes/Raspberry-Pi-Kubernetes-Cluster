#!/bin/bash

# Install DHCP Server
sudo apt-get install -y isc-dhcp-server
sudo service isc-dhcp-server stop

# bind IPV4 to eth0
sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="eth0"/g' /boot/config.txt

# Append required dhcp config to system config
cat dhcpd.conf | sudo tee -a /etc/dhcp/dhcpd.conf
