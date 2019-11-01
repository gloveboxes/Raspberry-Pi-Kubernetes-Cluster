#!/bin/bash

SCRIPTS_DIR="~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets"
kernel64bit=false
ipaddress=''
fanSHIM=false
bootFromUsb=false


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
    ssh -i ~/.ssh/id_rsa_rpi_kube_cluster pi@$hostname $1
}


function wait_for_network() {
  echo
  printf "Waiting for network connection to Raspberry Pi."
  while :
  do
    # Loop until network response
    ping $hostname -c 2 > /dev/null
    if [ $? -eq 0 ]
    then
      break
    else
      printf "."
      sleep 2
    fi    
  done 
  echo -e " Connected.\n"
  sleep 2
}


function wait_for_ready () {
  sleep 4
  echo "Waiting for the Raspberry Pi to be ready."

  while :
  do
    # Loop until you can successfully execute a command on the remote system
    remote_cmd 'uname -a' 2> /dev/null
    if [ $? -eq 0 ]
    then
      echo "Waiting"
      break
    else
      sleep 4
    fi    
  done    
  echo -e "Ready.\n"
  sleep 2
}


while getopts i:n:fxhu flag; do
  case $flag in
    i)
      ipaddress=$OPTARG
      ;;
    f)
      fanSHIM=true
      ;;
    u)
      bootFromUsb=true
      ;;
    x)
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
if ! valid_ip $ipaddress
then
  echo "invalid IP Address entered. Try again"
  exit 1
fi


hostname=$ipaddress

wait_for_network

wait_for_ready

echo -e "\nDownloading installation bootstrap onto the Raspberry Pi\n"
remote_cmd 'sudo rm -r -f Raspberry-Pi-Kubernetes-Cluster-master'
remote_cmd 'sudo wget -q https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/archive/master.zip'
remote_cmd 'sudo unzip -qq master.zip'
remote_cmd 'sudo rm master.zip'

echo -e "\nSetting Execution Permissions for installation scripts\n"
remote_cmd 'sudo chmod +x ~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/*.sh'
remote_cmd "sudo chmod +x $SCRIPTS_DIR/common/*.sh"
remote_cmd "sudo chmod +x $SCRIPTS_DIR/master/*.sh"



# enable boot from USB
if $bootFromUsb
then
  BOOT_USB3=false

  while :
  do
      BOOT_USB3=false
      echo 

      remote_cmd "lsblk" 
      echo
      echo -e "\nListed are all the available block devices\n"
      echo -e "This script assumes only ONE USB Drive is connected to the Raspberry Pi at /dev/sda"
      echo -e "This script will DELETE ALL existing partitions on the USB drive at /dev/sda"
      echo -e "A new primary partition is created and formated as /dev/sda1\n"

      read -p "Do you wish proceed? ([Y]es, [N]o, [R]efresh): " response

      case $response in
      [Yy]* ) BOOT_USB3=true; break;;
      [Nn]* ) break;;
      [Rr]* ) continue;;
      * ) echo "Please answer [Y]es, or [N]o).";;
      esac
  done

  if [ "$BOOT_USB3" = true ]; then
    remote_cmd "$SCRIPTS_DIR/common/boot-from-usb.sh"
    wait_for_ready
  fi
fi


# Enable 64bit Kernel
if $kernel64bit
then
  # r=$(sed -n "/arm_64bit=1/=" /boot/config.txt)

  # if [ "$r" = "" ]
  # then
    echo -e "\nEnabling 64bit Linux Kernel\n"
    remote_cmd 'echo "arm_64bit=1" | sudo tee -a /boot/config.txt > /dev/null'
    remote_cmd 'sudo reboot'

    wait_for_ready
  # fi
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