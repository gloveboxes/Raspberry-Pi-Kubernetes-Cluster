#!/bin/bash

nodeCount=1
set64BitKernelFlag=''
setFanShimFlag=''
setBootFromUsbFlag=''
devices=''


function getNextNodeNumber() {
    while :
    do
        ping "k8snode$nodeCount.local" -c 1 &> /dev/null
        if [ $? -ne 0 ]
        then 
            break
        else
            ((nodeCount++))
        fi
    done
}

function StartNodeInstall() {
    # devices=$(dhcp-lease-list --parsable 2>/dev/null |  egrep -o 'IP.*|' | awk '{print $2 ":"  $4}')
    for i in $devices
    do 
        ipaddress=$(echo $i | cut -f1 -d:)
        hostname=$(echo $i | cut -f2 -d:)

        if [ "$hostname" = "raspberrypi" ]; then
            getNextNodeNumber
            echo -e "\nStarting installation for device $ipaddress\n"
            ./install-node-auto.sh -i $ipaddress -n $nodeCount $set64BitKernelFlag $setFanShimFlag $setBootFromUsbFlag
            ((nodeCount++))
        fi
    done
}

function ListDevices() {
    while :
    do
        echo -e "\nThe follow table lists Kubernetes Node Candidates.\n"
        dhcp-lease-list 2>/dev/null
        devices=$(dhcp-lease-list --parsable 2>/dev/null |  egrep -o 'IP.*|' | awk '{print $2 ":"  $4}')

        echo -e "\nKubernetes only be installed on devices with a hostname of 'raspberrypi'"
        read -p "Are all devices to be configured as Kubernetes Nodes listed? ([Y]es, [N]o to refresh.): " response
        case $response in
            [Yy]* ) break;;
            [Nn]* ) continue;;
            * ) echo "Please answer [Y]es, [N]o).";;
        esac
    done
}

function EnableBootFromUSB() {
    while :
    do
        echo ""
        read -p "Enable Boot from USB ? ([Y]es, [N]o): " response
        case $response in
            [Yy]* ) setBootFromUsbFlag='-u'; break;;
            [Nn]* ) setBootFromUsbFlag=''; break;;
            * ) echo "Please answer [Y]es, [N]o).";;
        esac
    done
}

function Enable64BitKernel() {
    while :
    do
        echo ""
        read -p "Enable 64 Bit Kernel on each Kubernetes Node (Raspberry Pi 3 or better) ? ([Y]es, [N]o): " kernel64bit
        case $kernel64bit in
            [Yy]* ) set64BitKernelFlag='-x'; break;;
            [Nn]* ) set64BitKernelFlag=''; break;;
            * ) echo "Please answer [Y]es, [N]o).";;
        esac
    done
}

function EnableFanShim() {
    while :
    do
        echo ""
        read -p "Install support for FanSHIM on each Raspberry Pi? ([Y]es, [N]o): " response
        case $response in
            [Yy]* ) setFanShimFlag='-f'; break;;
            [Nn]* ) setFanShimFlag=''; break;;
            * ) echo "Please answer [Y]es, [N]o).";;
        esac
    done
}

ListDevices
EnableBootFromUSB
Enable64BitKernel
EnableFanShim
StartNodeInstall