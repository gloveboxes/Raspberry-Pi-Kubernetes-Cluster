#!/bin/bash


function Confirm() {

    echo -e "\nThis script will install everything needed for a Raspberry Pi Kubernetes Cluster\n"

    echo -e "Always be careful when running scripts and commands copied"
    echo -e "from the internet. Ensure they are from a trusted source.\n"

    echo -e "If you want to see what this script does before running it,"
    echo -e "you should run: 'curl https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/setup.sh'\n"


    printf "Do you wish to continue? [y/N]: "
    read -n1 response

    if [ ! $response = 'y' ]
    then
        exit
    fi
}

Confirm
echo

cd ~/

curl -O -J -L https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/archive/master.zip

BOOTSTRAP_DIR=~/Raspberry-Pi-Kubernetes-Cluster-master
if [ -d "$BOOTSTRAP_DIR" ]; then
    echo -e "\nPermission required to remove existing Raspberry Pi Installation Bootstrap Directory\n"
    sudo rm -r -f ~/Raspberry-Pi-Kubernetes-Cluster-master
fi

unzip -qq Raspberry-Pi-Kubernetes-Cluster-master.zip
rm Raspberry-Pi-Kubernetes-Cluster-master.zip

echo -e "\nSetting Execute Permissions for Installation Scripts\n"
cd ~/Raspberry-Pi-Kubernetes-Cluster-master/scripts
sudo chmod +x *.sh

while true; do
    echo ""
    read -p "Kubernetes Master or Node Set Up? ([M]aster, [N]ode), or [Q]uit: " Kube_Setup_Mode
    case $Kube_Setup_Mode in
        [Mm]* ) break;;
        [Nn]* ) break;;
        [Qq]* ) exit 1;;
        * ) echo "Please answer [M]aster, [N]ode), or [Q]uit.";;
    esac
done

if [ $Kube_Setup_Mode = 'M' ] || [ $Kube_Setup_Mode = 'm' ]; then   
    ./install-master.sh
else 
    ./install-node.sh
fi