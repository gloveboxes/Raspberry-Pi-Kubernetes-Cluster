#!/bin/bash

SCRIPTS_DIR="~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets"

# Install DHCP Server
while : ;
do
  echo -e "\nInstalling and configuring DHCP Server\n"
  sudo apt-get install -y -qq isc-dhcp-server > /dev/null
  if [ $? -eq 0 ]
  then
    break
  else
    echo -e "\nDHCP server installation failed. Check Internet connection. Retrying in 20 seconds.\n"
    sleep 20
  fi
done

sudo service isc-dhcp-server stop

# bind IPV4 to eth0
sudo sed -i 's/INTERFACESv4=""/INTERFACESv4="eth0"/g' /etc/default/isc-dhcp-server > /dev/null
sudo sed -i 's/INTERFACESv6=""/INTERFACESv4="eth0"/g' /etc/default/isc-dhcp-server > /dev/null

# Append required dhcp config to system config
echo "$SCRIPTS_DIR/master/dhcpd.conf" 
cat $SCRIPTS_DIR/master/dhcpd.conf | sudo tee -a /etc/dhcp/dhcpd.conf > /dev/null

echo -e "\nStarting DHCP Server\n"

sudo service isc-dhcp-server start
