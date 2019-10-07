#!/bin/bash

# Install DHCP Server
sudo apt-get install isc-dhcp-server
sudo service isc-dhcp-server stop

sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="eth0"/g' /boot/config.txt

# Append required dhcp config to system config
cat dhcpd.conf | sudo tee -a /etc/dhcp/dhcpd.conf

sudo service isc-dhcp-server start