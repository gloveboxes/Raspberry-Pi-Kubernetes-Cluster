#!/bin/bash


set64BitKernelFlag=''
setFanShimFlag=''
ipaddress=''
setBootFromUsbFlag=''

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

function GetIpAddress() {
    while :
    do
        echo ""
        read -p "Enter the Raspberry Pi IP Address for the new Kubernetes Master: " ipaddress
        if valid_ip $ipaddress
        then
            ping $ipaddress -c 2 > /dev/null
            if [ $? -eq 0 ]
            then
                break
            else
                echo -e "\nIP Address not found on your network - check address!"
            fi
        else
            echo "invalid IP Address entered. Try again"
        fi
    done
}

function Generate_SSH() {

    if [ ! -f ~/.ssh/id_rsa_rpi_kube_cluster ]; then 

        echo -e "\nGenerating SSH Key for Raspberry Pi Kubernetes Cluster Automated Installation\n"

        if [ ! -d "~/.ssh" ]; then
            mkdir -p ~/.ssh
            echo -e "\nYou may be prompted for your local password to set the correct permissions for the ~/.ssh directory (700)\n"
            sudo chmod -R 700 ~/.ssh
        fi

        ssh-keygen -t rsa -N "" -b 4096 -f ~/.ssh/id_rsa_rpi_kube_cluster
      
    fi

    echo -e "\nAbout to copy the public SSH key to the Raspberry Pi."
    echo -e 'You will be prompted to "Accept continue connecting", type yes'
    echo -e "You will be prompted for the Raspberry Pi password. The default password is 'raspberry'\n"

    ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "$ipaddress" &> /dev/null
    ssh-keyscan -H $ipaddress >> ~/.ssh/known_hosts 2> /dev/null  # https://www.techrepublic.com/article/how-to-easily-add-an-ssh-fingerprint-to-your-knownhosts-file-in-linux/

    ssh-copy-id -i ~/.ssh/id_rsa_rpi_kube_cluster pi@$ipaddress 
}

GetIpAddress
EnableBootFromUSB
Enable64BitKernel
EnableFanShim
Generate_SSH

./install-master-auto.sh -i $ipaddress $set64BitKernelFlag $setFanShimFlag $setBootFromUsbFlag
