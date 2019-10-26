#!/bin/bash

function ListDevices() {
    while :
    do
        dhcp-lease-list 2>/dev/null

        read -p "The listed devices will be shutdown. Proceed? ([Y]es, [N]o): " response
        case $response in
            [Yy]* ) break;;
            [Nn]* ) exit 0;;
            * ) echo "Please answer [Y]es, [N]o).";;
        esac
    done
}

function runCommand() {
    devices=$(dhcp-lease-list --parsable 2>/dev/null |  egrep -o 'IP.*|' | awk '{print $2 ":"  $4}')
    for i in $devices
    do 
        hostname=$(echo $i | cut -f1 -d:)
        echo "Shutting down $ipaddress"

        ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "$hostname"
        ssh-keyscan -H $hostname >> ~/.ssh/known_hosts

        sshpass -p "raspberry" ssh $hostname 'sudo halt'
    done
}

ListDevices
runCommand
sudo halt