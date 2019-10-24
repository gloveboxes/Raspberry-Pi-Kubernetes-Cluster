#!/bin/bash

devices=$(dhcp-lease-list --parsable 2>/dev/null |  egrep -o 'IP.*|' | awk '{print $2 ":"  $4}')

nodeCount=1

function getNextNodeNumber() {
    while :
    do
        ping "k8snode$nodeCount.local" -c 1
        if [ $? -ne 0 ]
        then 
          break
        else
         ((nodeCount++))
        fi
    done
}

for i in $devices
do 
    ipaddress=$(echo $i | cut -f1 -d:)
    hostname=$(echo $i | cut -f2 -d:)

    echo "IP Address $ipaddress"
    echo "Hostname $hostname"

    if [ "$hostname" = "raspberrypi" ]; then
        getNextNodeNumber
        ./install-node-auto.sh -i $ipaddress -n $nodeCount -f -x
        ((nodeCount++))
    fi
done