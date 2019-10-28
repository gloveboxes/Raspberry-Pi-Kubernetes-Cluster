#!/bin/bash

SCRIPTS_DIR="~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets"
kernel64bit=false
ipaddress=''
fanSHIM=false


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


function remote_cmd() {
    sshpass -p "raspberry" ssh pi@$hostname $1
}


function wait_for_network() {
  while :
  do
    # Loop until network response
    ping $hostname -c 4
    if [ $? -eq 0 ]
    then
      break
    else
      sleep 2
    fi    
  done 
  sleep 2
}


function wait_for_ready () {
  sleep 4

  while :
  do
    # Loop until you can successfully execute a command on the remote system
    remote_cmd 'uname -a'
    if [ $? -eq 0 ]
    then
      break
    else
      sleep 4
    fi    
  done    

  sleep 2
}


while getopts i:n:fxh flag; do
  case $flag in
    i)
      ipaddress=$OPTARG
      ;;
    f)
      echo "Enable Fan SHIM"
      fanSHIM=true
      ;;
    x)
      echo "Enable 64bit Kernel"
      kernel64bit=true
      ;;
    h)
      echo "Startup options -i Master IP Address, Optional: -f Install FanSHIM support, -x Enable Linux 64bit Kernel"
      exit 0
      ;;   
    *)
      echo "Startup options -i Master IP Address, Optional: -f Install FanSHIM support, -x Enable Linux 64bit Kernel"
      exit 1;
      ;;
  esac
done


if [ -z "$ipaddress" ]
then
  echo -e "\nExpected -i IP Address."
  echo -e "Startup options -i Master IP Address, Optional: -f Install FanSHIM support, -x Enable Linux 64bit Kernel\n"
  exit 1
fi

# Validate IP Address
if valid_ip $ipaddress
then
  echo 'good ip address'
else
  echo "invalid IP Address entered. Try again"
  exit 1
fi


hostname=$ipaddress

wait_for_network

# Remove any existing ssh finger prints for the device
echo -e "\nDeleting existing SSH Fingerprint for $hostname\n"
ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "$hostname"
ssh-keyscan -H $hostname >> ~/.ssh/known_hosts  # https://www.techrepublic.com/article/how-to-easily-add-an-ssh-fingerprint-to-your-knownhosts-file-in-linux/

wait_for_ready

echo -e "\nDownloading installation bootstrap\n"
remote_cmd 'sudo rm -r -f Raspberry-Pi-Kubernetes-Cluster-master'
remote_cmd 'sudo wget -q https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/archive/master.zip'
remote_cmd 'sudo unzip -qq master.zip'
remote_cmd 'sudo rm master.zip'

echo -e "\nSetting Execution Permissions for installation scripts\n"
remote_cmd 'sudo chmod +x ~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/*.sh'
remote_cmd "sudo chmod +x $SCRIPTS_DIR/common/*.sh"
remote_cmd "sudo chmod +x $SCRIPTS_DIR/master/*.sh"

# Enable 64bit Kernel
if $kernel64bit
then

  r=$(sed -n "/arm_64bit=1/=" /boot/config.txt)
  
  if [ "$r" = "" ]
  then

    echo -e "\nEnabling 64bit Linux Kernel\n"
    remote_cmd 'echo "arm_64bit=1" | sudo tee -a /boot/config.txt > /dev/null'
    remote_cmd 'sudo reboot'

    wait_for_ready

  fi
fi

# Update, set config, rename and reboot
echo -e "\nUpdating System, configuring prerequisites, renaming, rebooting\n"
remote_cmd "$SCRIPTS_DIR/master/install-init.sh"

wait_for_ready

# Static network IP on eth0 , set up packet passthrough to wlan
remote_cmd "$SCRIPTS_DIR/master/setup-networking.sh"

# Install DHCP Server
remote_cmd "$SCRIPTS_DIR/master/install-dhcp-server.sh"

# Install NFS
remote_cmd "$SCRIPTS_DIR/master/install-nfs.sh"

# Install Docker
echo "Installing Docker"
remote_cmd "$SCRIPTS_DIR/common/install-docker.sh"

wait_for_ready

# Install Kubernetes Master
echo -e "\nInstalling Kubernetes\n"
remote_cmd "$SCRIPTS_DIR/common/install-kubernetes.sh"

# Initialise Kubernetes Master
echo -e "\nInitializing Kubernetes\n"
remote_cmd "$SCRIPTS_DIR/master/kubernetes-init.sh"

# Set Up Kubernetes - Flannel, persistent storage, nginx
echo -e "\nSetting Up Kubernetes\n"
remote_cmd "$SCRIPTS_DIR/master/kubernetes-setup.sh"

if $fanSHIM
then
  echo -e "\nInstalling FanSHIM\n"
  remote_cmd "$SCRIPTS_DIR/common/install-fanshim.sh"
fi