CHECKPOINT='~/.node-init-completed'

if [ -f "$CHECKPOINT" ]; then
    echo "Update already completed"
    exit 0
fi

if [[ -z "$1" || -n ${NodeNumber//[0-9]/} ]]; 
then
    echo "Node number needs to be passed to bash script. Either number missing or not a number!"
    exit 1
fi

while : ;
do
    sudo apt-get update && sudo apt-get upgrade -y 
    if [ $? -eq 0 ]
    then
        break;
    else
        echo -e "\nUpdate failed. Retrying system update in 10 seconds\n"
        sleep 10
    fi
done

# enable 64bit
echo -e "\nEnabling 64bit Linux Kernel\n"
echo "arm_64bit=1" | sudo tee -a /boot/config.txt > /dev/null


echo -e "iptables to legacy mode"
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

#disable swap
echo -e "Disabling Linux Swap file\n"
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo systemctl disable dphys-swapfile

# maximise memory by reducing gpu memory
echo "gpu_mem=16" | sudo tee -a /boot/config.txt
# disable wifi on the node board as network will be over Ethernet
echo "dtoverlay=disable-wifi" | sudo tee -a /boot/config.txt

# Disable hdmi to reduce power consumption
sudo sed -i -e '$i \/usr/bin/tvservice -o\n' /etc/rc.local

# Disk optimisations - move temp to ram.
# Reduce writes to the SD Card and increase IO performance by mapping the /tmp and /var/log directories to RAM. 
# Note you will lose the contents of these directories on reboot.
echo "tmpfs /tmp  tmpfs defaults,noatime 0 0" | sudo tee -a /etc/fstab
echo "tmpfs /var/log  tmpfs defaults,noatime,size=30m 0 0" | sudo tee -a /etc/fstab

# enable cgroups for Kubernetes
sudo sed -i 's/$/ ipv6.disable=1 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt

sudo raspi-config nonint do_hostname "k8snode$1"

sudo reboot