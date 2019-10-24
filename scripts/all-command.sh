#!/bin/bash

function ListDevices() {
    while :
    do
        dhcp-lease-list 2>/dev/null

        read -p "The listed devices will be restarted. Proceed? ([Y]es, [N]o): " response
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
        ipaddress=$(echo $i | cut -f1 -d:)
        sshpass -p "raspberry" ssh $ipaddress 'sudo $@'
    done
}

ListDevices
runCommand
