#!/bin/bash


set64BitKernelFlag=''
setFanShimFlag=''
ipaddress=''

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
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

function GetIpAddress() {
    while :
    do
        echo ""
        read -p "Enter the Raspberry Pi IP Address for the new Kubernetes Master: " ipaddress
        if valid_ip $ipaddress
        then
            break
        else
            echo "invalid IP Address entered. Try again"
        fi
    done
}

GetIpAddress
Enable64BitKernel
EnableFanShim

./install-master-auto.sh -i $ipaddress $set64BitKernelFlag $setFanShimFlag
