#!/bin/bash

devices=$(dhcp-lease-list --parsable 2>/dev/null |  egrep -o 'IP.*|' | awk '{print $2 ":"  $4}')

for i in $devices
do 
    ipaddress=$(echo $i | cut -f1 -d:)
    echo "IP Address $ipaddress"

    sshpass -p "raspberry" ssh $ipaddress 'sudo halt -p'

done

sudo halt