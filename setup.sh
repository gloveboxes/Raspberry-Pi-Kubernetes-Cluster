#!/bin/bash

cd ~/

wget -q https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/archive/master.zip

BOOTSTRAP_DIR=~/Raspberry-Pi-Kubernetes-Cluster-master
if [ -d "$BOOTSTRAP_DIR" ]; then
    echo -e "\nPermission required to remove existing Raspberry Pi Installation Bootstrap Directory\n"
    sudo rm -r -f ~/Raspberry-Pi-Kubernetes-Cluster-master
fi

unzip -qq master.zip
rm master.zip

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