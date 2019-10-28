#!/bin/bash

# https://sysadmins.co.za/setup-a-nfs-server-and-client-on-the-raspberry-pi/
# https://vitux.com/install-nfs-server-and-client-on-ubuntu/

# Make the nfs directory to be shared
mkdir -p ~/nfsshare
mkdir -p ~/nfsshare/nginx

# Change ownership recurse
sudo chown -R nobody:nogroup /home/pi/nfsshare
# ‘777’ permission, everyone can read, write and execute the file, recurse
sudo chmod -R 777 /home/pi/nfsshare
echo "Hello, World!" > /home/pi/nfsshare/nginx/index.html

# available to * (all) IP address on the cluster
echo "/home/pi/nfsshare *(rw,async,no_subtree_check)" | sudo tee -a /etc/exports  > /dev/null
echo "/home/pi/nfsshare/nginx *(rw,async,no_subtree_check)" | sudo tee -a /etc/exports  > /dev/null

# reload exports
sudo exportfs -ra

# Restart the NFS Server
sudo systemctl restart nfs-kernel-server

# show what's being shared
# showmount -e localhost
