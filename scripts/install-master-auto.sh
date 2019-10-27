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
    ping $hostname -c 2
    if [ $? -eq 0 ]
    then
      break
    else
      sleep 2
    fi    
  done 
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
echo "deleting existing key for $hostname"
ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "$hostname"
ssh-keyscan -H $hostname >> ~/.ssh/known_hosts  # https://www.techrepublic.com/article/how-to-easily-add-an-ssh-fingerprint-to-your-knownhosts-file-in-linux/

wait_for_ready

echo "Downloading installation bootstrap"
remote_cmd 'sudo rm -r -f Raspberry-Pi-Kubernetes-Cluster-master'
remote_cmd 'sudo wget -q https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/archive/master.zip'
remote_cmd 'sudo unzip -qq master.zip'
remote_cmd 'sudo rm master.zip'

echo "Setting Execution Permissions for installation scripts"
remote_cmd 'sudo chmod +x ~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/*.sh'
remote_cmd "sudo chmod +x $SCRIPTS_DIR/common/*.sh"
remote_cmd "sudo chmod +x $SCRIPTS_DIR/master/*.sh"

echo -e "Updating System, configuring prerequisites, renaming, rebooting"

if $kernel64bit
then
  echo -e "\nEnabling 64bit Linux Kernel\n"
  remote_cmd 'echo "arm_64bit=1" | sudo tee -a /boot/config.txt > /dev/null'
fi

# Static network IP on eth0 , set up packet passthrough to wlan
remote_cmd "$SCRIPTS_DIR/master/setup-networking.sh"

# Update, set config, rename and reboot
remote_cmd "$SCRIPTS_DIR/master/install-init.sh"

wait_for_ready

# Install DHCP Server
remote_cmd "$SCRIPTS_DIR/master/install-dhcp-server.sh"

# Install NFS
remote_cmd "$SCRIPTS_DIR/master/install-nfs.sh"

echo "Installing Docker"
remote_cmd "$SCRIPTS_DIR/common/install-docker.sh"

wait_for_ready

echo "Installing Kubernetes"
remote_cmd "$SCRIPTS_DIR/common/install-kubernetes.sh"


echo "Initializing Kubernetes"
remote_cmd "$SCRIPTS_DIR/master/kubernetes-init.sh"

echo "Setting Up Kubernetes"
remote_cmd "$SCRIPTS_DIR/master/kubernetes-setup.sh"

if $fanSHIM
then
  echo "Installing FanSHIM"
  remote_cmd "$SCRIPTS_DIR/common/install-fanshim.sh"
fi