sudo apt update && sudo apt install -y git

git clone https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster.git ~/kube-setup

cd ~/kube-setup/scripts
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