#!/bin/bash

kernel64bit=false
ipaddress=''
k8snodeNumber=''
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


function wait_for_restart () {
  sleep 2
  while : ; do
    ping  $1 -c 2
    if [ $? -eq 0 ]
    then
      break
    else
       echo -e "Waiting for host $1"
       sleep 2
    fi
  done
  sleep 10
}

function execute_command() {
  while :
  do
    echo "Execute Command - Parameters"
    echo $1
    echo $2
    sshpass -p "raspberry" ssh '$1' '$2'
    if $? -eq 0
    then
      break
    else
      sleep 6
    fi
  done
}


while getopts i:n:fxh flag; do
  case $flag in
    i)
      ipaddress=$OPTARG
      ;;
    n)
      k8snodeNumber=$OPTARG
      ;;
    f)
      fanSHIM=true
      ;;
    x)
      kernel64bit=true
      ;;
    h)
      echo "Startup options -i Node IP Address, -n Node Number, Optional: -f Install FanSHIM support, -x Enable Linux 64bit Kernel"
      exit 0
      ;;   
    *)
      echo "Startup options -i Node IP Address, -n Node Number, Optional: -f Install FanSHIM support, -x Enable Linux 64bit Kernel"
      exit 1;
      ;;
  esac
done

if [ -z "$ipaddress" ] || [ -z "$k8snodeNumber" ]
then
  echo -e "\nExpected -i IP Address and -n Kubernetes Node Number."
  echo -e "Startup options -i Node IP Address, -n Node Number, Optional: -f Install FanSHIM support, -x Enable Linux 64bit Kernel\n"
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

# Validate node number is numeric
if [[ -z "$k8snodeNumber" || -n ${NodeNumber//[0-9]/} ]];
then
    echo "Kubernetes Node number not numeric!"
    exit 1
fi

hostname=$ipaddress

wait_for_restart $hostname

# delete existing kubernetes node
kubectl delete node k8snode$k8snodeNumber

# Remove any existing ssh finger prints for the device
ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "k8snode$k8snodeNumber.local"
ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "$hostname"
# Generate ssh fingerprint
# https://www.techrepublic.com/article/how-to-easily-add-an-ssh-fingerprint-to-your-knownhosts-file-in-linux/
ssh-keyscan -H $hostname >> ~/.ssh/known_hosts

sshpass -p "raspberry" scp ~/k8s-join-node.sh $hostname:~/

echo "Adding execute rights to k8s-join-node.sh"
execute_command  $hostname 'sudo chmod +x ~/k8s-join-node.sh'

echo "Downloading installation bootstrap"
execute_command $hostname 'sudo rm -r -f Raspberry-Pi-Kubernetes-Cluster-master'
execute_command $hostname 'sudo wget -q https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/archive/master.zip'
execute_command $hostname 'sudo unzip -qq master.zip'
execute_command $hostname 'sudo rm master.zip'
execute_command $hostname 'sudo chmod +x ~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/*.sh'
execute_command $hostname 'sudo chmod +x ~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/*.sh'

echo -e "Updating System, configuring prerequisites, renaming, rebooting"

if $kernel64bit
then
  echo -e "\nEnabling 64bit Linux Kernel\n"
  execute_command $hostname 'echo "arm_64bit=1" | sudo tee -a /boot/config.txt > /dev/null'
fi

# Update, set config, rename and reboot
execute_command $hostname "~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/install-init.sh $k8snodeNumber"

wait_for_restart $hostname

if $fanSHIM
then
  echo "Installing FanSHIM"
  execute_command $hostname '~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/install-fanshim.sh'
fi

echo "Installing Docker"
execute_command  $hostname '~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/install-docker.sh'

wait_for_restart $hostname

echo "Installing Kubernetes"
execute_command $hostname '~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/install-kubernetes.sh'

echo "Joining Node to Kubernetes Master"
execute_command $hostname 'sudo ~/k8s-join-node.sh'

echo -e "\nInstallation Completed!\n"