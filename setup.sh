#!/bin/bash


cd ~/

wget -q https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/archive/master.zip

# echo -e "\nInstall unzip and sshpass dependencies\n"
# sudo apt-get update && sudo apt-get install -y -qq unzip sshpass

sudo rm -r -f ~/Raspberry-Pi-Kubernetes-Cluster-master
unzip -qq master.zip
rm master.zip

# git clone https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster.git ~/kube-setup

# cd ~/kube-setup/scripts

echo "Setting Execute Permissions for Installation Scripts"
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
    ./install-master-v2.sh
else 
    ./install-node.sh
fi