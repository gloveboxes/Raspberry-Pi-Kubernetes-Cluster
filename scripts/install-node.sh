#!/bin/bash

STATE=~/.KubeNodeInstallState
RUNNING=true

sed --in-place '/~\/kube-setup\/scripts\/install-node.sh/d' ~/.bashrc
echo "~/kube-setup/scripts/install-node.sh" >> ~/.bashrc

echo -e "\n\nThis is a mult-stage installer.\nSome stages require a reboot.\nInstallation will automatically restart.\n\n"

while $RUNNING; do
  case $([ -f $STATE ] && cat $STATE) in

    INIT)
        # Rename your pi
        while :
        do
            echo -e "\nNumber this Raspberry Pi/Kubernetes Node. The first node should be numbered should be numbered 1"
            echo -e "as it will also run the NFS Server for Cluster Persistent Storage Services.\n"
            read -p "Enter an Integer, the node will be named k8snodeN: " NodeNumber
            if [[ -z "$NodeNumber" || -n ${NodeNumber//[0-9]/} ]]; then
                echo "Not a number!"
            else
                break;
            fi
        done

        RPINAME="k8snode${NodeNumber}"
        echo -e "\nNaming this Raspberry Pi/Kubernetes Node ${RPINAME}\n"
        sudo raspi-config nonint do_hostname $RPINAME

        if [ $NodeNumber == 1 ]; then 
            echo "NFS" > $STATE
        else
            echo "SSD" > $STATE
        fi

        # not 100% necessary but it is safer
        echo -e "\nThe system will reboot. Log back in, remember to use new system name.\nssh pi@${NodeNumber}\nSet up will automatically continue.\n"
        sudo reboot
        
    ;;

    NFS)
        echo -e "\nInstalling NFS Server on k8snode1 for use as Cluster Storage Class and Persistent Storage\n"
        # https://sysadmins.co.za/setup-a-nfs-server-and-client-on-the-raspberry-pi/
        # https://vitux.com/install-nfs-server-and-client-on-ubuntu/
        
        sudo apt install -y nfs-kernel-server

        # Make the nfs directory to be shared
        mkdir -p ~/nfsshare
        sudo chown nobody:nogroup /home/pi/nfsshare
        # ‘777’ permission, everyone can read, write and execute the file
        sudo chmod 777 /home/pi/nfsshare

        # available to * (all) IP address on the cluster
        echo "/home/pi/nfsshare *(rw,async,no_subtree_check)" | sudo tee -a /etc/exports
 
        # reload exports
        sudo exportfs -ra

        # Restart the NFS Server
        sudo systemctl restart nfs-kernel-server

        # show what's being shared
        showmount -e localhost

        echo "SSD" > $STATE
    ;;

    SSD)
        BOOT_USB3=false
        while true; do
            echo -e "\nThis script assumes the USB3 SSD Drive is mounted at /dev/sda ready for partitioning and formating" 
            read -p "Do you wish to enable USB3 SSD Boot Support [yes(y), no(n), or quit(q)] ?" yn
            case $yn in
                [Yy]* ) BOOT_USB3=true; break;;
                [Qq]* ) RUNNING=false; exit 1;;
                [Nn]* ) break;;
                * ) echo "Please answer yes(y), no(n), or quit(q).";;
            esac
        done

        echo "UPDATE" > $STATE

        if [ "$BOOT_USB3" = true ]; then
            echo -e "\np = print partitions, \nd = delete a partition, \nn = new partition -> create a primary partition, \nw = write the partition information to disk, \nq = quit\n"
            sudo fdisk /dev/sda
            sudo mkfs.ext4 /dev/sda1
            sudo mkdir /media/usbdrive
            sudo mount /dev/sda1 /media/usbdrive
            sudo rsync -avx / /media/usbdrive
            sudo sed -i '$s/$/ root=\/dev\/sda1 rootfstype=ext4 rootwait/' /boot/cmdline.txt
            echo -e "\nThe system will reboot. Log back in, remember to use new system name. Set up will automatically continue.\n"
            sudo reboot
        fi
        ;;

    UPDATE)
        OS_UPDATE=false
        while true; do
            read -p "Do you wish to update the Raspberry Pi Operating System (Recommended) [yes(y), no(n), or quit(q)] ?" yn
            case $yn in
                [Yy]* ) OS_UPDATE=true; break;;
                [Qq]* ) RUNNING=false; exit 1;;
                [Nn]* ) break;;
                * ) echo "Please answer yes(y), no(n), or quit(q).";;
            esac
        done

        echo "FANSHIM" > $STATE
        if [ "$OS_UPDATE" = true ]; then
            sudo apt update && sudo apt upgrade -y 
            echo -e "\nThe system will reboot. Log back in, remember to use new system name. Set up will automatically continue.\n"
            sudo reboot
        fi
        ;;    

    FANSHIM)
        INSTALL_FAN_SHIM=false
        while true; do
            read -p "Do you wish to Install Fan SMIM Support [yes(y), no(n), or quit(q)] ?" yn
            case $yn in
                [Yy]* ) INSTALL_FAN_SHIM=true; break;;
                [Qq]* ) RUNNING=false; exit 1;;
                [Nn]* ) break;;
                * ) echo "Please answer yes(y), no(n), or quit(q).";;
            esac
        done

        echo "PREREQUISITES" > $STATE

        if [ "$INSTALL_FAN_SHIM" = true ]; then
            sudo apt install -y python3-pip
            git clone https://github.com/pimoroni/fanshim-python && \
            cd fanshim-python && \
            sudo ./install.sh && \
            cd examples && \
            sudo ./install-service.sh --on-threshold 65 --off-threshold 55 --delay 2
        fi
        ;;

    PREREQUISITES) 
        # Set iptables in legacy mode - required for Kube compatibility
        # https://github.com/kubernetes/kubernetes/issues/71305

        echo -e "\nSetting Prerequisites\n"
        echo -e "iptables to legacy mode, swap off, gpu mem min, disable wifi, tmpfs optimisations, cgroups for kube\n"
        sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
        sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

        #disable swap
        sudo dphys-swapfile swapoff
        sudo dphys-swapfile uninstall
        sudo systemctl disable dphys-swapfile

        # maximise memory by reducing gpu memory
        echo "gpu_mem=16" | sudo tee -a /boot/config.txt
        # disable wifi on the node board as network will be over Ethernet
        echo "dtoverlay=disable-wifi" | sudo tee -a /boot/config.txt

        # Disk optimisations - move temp to ram.
        # Reduce writes to the SD Card and increase IO performance by mapping the /tmp and /var/log directories to RAM. 
        # Note you will lose the contents of these directories on reboot.
        echo "tmpfs /tmp  tmpfs defaults,noatime 0 0" | sudo tee -a /etc/fstab
        echo "tmpfs /var/log  tmpfs defaults,noatime,size=30m 0 0" | sudo tee -a /etc/fstab

        # enable cgroups for Kubernetes
        sudo sed -i 's/$/ ipv6.disable=1 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt

        echo "DOCKER" > $STATE
    ;;

    DOCKER)
        echo -e "\nInstalling Docker\n"
        # Install Docker
        curl -sSL get.docker.com | sh && sudo usermod $USER -aG docker

        echo "KUBERNETES" > $STATE
        echo -e "\nThe system will reboot. Log back in, remember to use new system name. Set up will automatically continue.\n"
        sudo reboot        
    ;;

    KUBERNETES)
        echo -e "\nInstalling Kubernetes\n"
        # Install Kubernetes
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        sudo apt-get update -q
        sudo apt-get install -qy kubeadm

        echo "BREAK" > $STATE
    ;;

    BREAK)
      RUNNING=false
      ;;
    *)
      echo "INIT" > $STATE
      ;;
  esac
done


rm $STATE
sed --in-place '/~\/kube-setup\/scripts\/install-node.sh/d' ~/.bashrc

echo -e "\nFINISHED and ready for 'sudo kubeadm join'\n"