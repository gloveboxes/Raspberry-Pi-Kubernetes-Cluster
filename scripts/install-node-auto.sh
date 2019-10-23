#!/bin/bash

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
    ping  $1 -c 1
    if [ $? -eq 0 ]
    then
      break
    else
       echo -e "Waiting."
       sleep 2
    fi
  done
  sleep 10
}

if valid_ip $1
then
  echo 'good ip address'
else
  echo "invalid IP Adress entered. Try again"
  exit
fi


if [[ -z "$2" || -n ${NodeNumber//[0-9]/} ]];
then
    echo "Node number needs to be passed to bash script. Either number missing or not a number!"
    exit 1
fi

hostname=$1

ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "$hostname"

wait_for_restart $hostname

# Generate ssh fingerprint
# https://www.techrepublic.com/article/how-to-easily-add-an-ssh-fingerprint-to-your-knownhosts-file-in-linux/
ssh-keyscan -H $hostname >> ~/.ssh/known_hosts

sshpass -p "raspberry" scp ~/k8s-join-node.sh $hostname:~/

echo "Adding execute rights to k8s-join-node.sh"
sshpass -p "raspberry" ssh $hostname 'sudo chmod +x ~/k8s-join-node.sh'
echo "Downloading installation bootstrap"
sshpass -p "raspberry" ssh $hostname 'sudo rm -r -f Raspberry-Pi-Kubernetes-Cluster-master'
sshpass -p "raspberry" ssh $hostname 'sudo wget -q https://github.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/archive/master.zip'
sshpass -p "raspberry" ssh $hostname 'sudo unzip -qq master.zip'
echo "Unzipping Bootstrap"
sshpass -p "raspberry" ssh $hostname 'sudo rm master.zip'
sshpass -p "raspberry" ssh $hostname 'sudo chmod +x ~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/*.sh'
sshpass -p "raspberry" ssh $hostname 'sudo chmod +x ~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/*.sh'

echo -e "Updating System, configuraing prerequistes, renaming, rebooting"
sshpass -p "raspberry" ssh $hostname "~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/install-init.sh $2"

ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "$hostname"

hostname="k8snode$2.local"
echo $hostname

ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "$hostname"

wait_for_restart $hostname

ssh-keyscan -H $hostname >> ~/.ssh/known_hosts

echo "Installing FanSHIM"
sshpass -p "raspberry" ssh $hostname '~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/install-fanshim.sh'

# echo "Installing Prerequisites"
# sshpass -p "raspberry" ssh $hostname '~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/install-prerequisites.sh'

echo "Installing Docker"
sshpass -p "raspberry" ssh $hostname '~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/install-docker.sh'

wait_for_restart $hostname

echo "Installing Kubernetes"
sshpass -p "raspberry" ssh $hostname '~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/scriptlets/install-kubernetes.sh'

sleep 6
echo "Joining Node to Kubernetes Master"
sshpass -p "raspberry" ssh $hostname 'sudo ~/k8s-join-node.sh'