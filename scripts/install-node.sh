#!/bin/bash

STATE=~/.KubeNodeInstallState
RUNNING=true

sed --in-place '/~\/Raspberry-Pi-Kubernetes-Cluster-master\/scripts\/install-node.sh/d' ~/.bashrc
echo "~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/install-node.sh" >> ~/.bashrc

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

        while true; do
            echo ""
            read -p "Enable 64 Bit Kernel (Raspberry Pi 3 or better)? ([Y]es, [N]o): " kernel64bit
            case $kernel64bit in
                [Yy]* ) break;;
                [Nn]* ) break;;
                * ) echo "Please answer [Y]es, [N]o).";;
            esac
        done

        if [ $kernel64bit = 'Y' ] || [ $kernel64bit = 'y' ]; then  
            echo -e "\nEnabling 64 Bit Linux Kernel\n" 
            echo "arm_64bit=1" | sudo tee -a /boot/config.txt > /dev/null
        fi

        echo -e "\nUpdating the Raspberry Pi System\n"

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

        RPINAME="k8snode${NodeNumber}"
        echo -e "\nNaming this Raspberry Pi/Kubernetes Node ${RPINAME}\n"

        echo "SSD" > $STATE

        echo -e "\nThe system will reboot. Log back in, remember to use new system name.\nssh pi@${RPINAME}.local\nSet up will automatically continue.\n"
        
        sudo raspi-config nonint do_hostname $RPINAME
        
        sudo reboot
        
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

        echo "FANSHIM" > $STATE

        if [ "$BOOT_USB3" = true ]; then
            echo -e "\np = print partitions, \nd = delete a partition, \nn = new partition -> create a primary partition, \nw = write the partition information to disk, \nq = quit\n"
            sudo fdisk /dev/sda
            sudo mkfs.ext4 /dev/sda1
            sudo mkdir /media/usbdrive
            sudo mount /dev/sda1 /media/usbdrive
            sudo rsync -avx / /media/usbdrive
            sudo sed -i '$s/$/ root=\/dev\/sda1 rootfstype=ext4 rootwait/' /boot/cmdline.txt
            
            echo -e "\nThe system will reboot. Log back in as pi@$(hostname).local.\nThe set up will continue automatically.\n"
  
            sudo reboot
        fi
    ;;

    FANSHIM)
        INSTALL_FAN_SHIM=false
        while true; do
            read -p "Do you wish to Install Pimoroni Fan SMIM Support [yes(y), no(n), or quit(q)] ?" yn
            case $yn in
                [Yy]* ) INSTALL_FAN_SHIM=true; break;;
                [Qq]* ) RUNNING=false; exit 1;;
                [Nn]* ) break;;
                * ) echo "Please answer yes(y), no(n), or quit(q).";;
            esac
        done

        echo "PREREQUISITES" > $STATE

        if [ "$INSTALL_FAN_SHIM" = true ]; then
            sleep 10 # let system settle
            sudo apt install -y python3-pip

            if [ $? -ne 0 ]
            then
                echo "\nFanSHIM installation failed. Retrying in 10 Seconds\n"
                sleep 10
                continue
            fi

            cd ~/

            wget https://github.com/pimoroni/fanshim-python/archive/master.zip
            unzip ~/master.zip
            rm ~/master.zip

            cd fanshim-python-master

            sudo ./install.sh
            if [ $? -ne 0 ]
            then
                echo "\nFanSHIM installation failed. Retrying in 10 Seconds\n"
                sleep 10
                continue
            fi

            cd examples
            sudo ./install-service.sh --on-threshold 70 --off-threshold 55 --delay 2
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

        # Disable hdmi to reduce power consumption
        sudo sed -i -e '$i \/usr/bin/tvservice -o\n' /etc/rc.local

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
        sudo docker --version
        if [ $? -ne 0 ]
        then
          while : ;
          do
            curl -sSL get.docker.com | sh && sudo usermod $USER -aG docker
            if [ $? -eq 0 ]
            then
              break
            else
              echo -e "\nDocker installation failed. Check internet connection. Retrying in 20 seconds.\n"
              sleep 20
            fi
          done
        fi

        sudo docker --version

        echo "KUBERNETES" > $STATE
        echo -e "\nThe system will reboot. Log back in as pi@$(hostname).local.\nThe set up will continue automatically.\n"
        sudo reboot   
    ;;

    KUBERNETES)

        docker --version
        
        echo -e "\nInstalling Kubernetes\n"
        # Install Kubernetes
        while : ;
        do
          curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
          if [ $? -eq 0 ]
          then
            break
          else
            echo -e "\nGet Kuberetes key failed. Check internet connection. Retrying in 20 seconds.\n"
            sleep 20
          fi
        done

        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

        while : ;
        do
          echo -e "\nInstalling Kubernetes\n"
          sudo apt-get update -qq && sudo apt-get install -qq -y kubeadm
          if [ $? -eq 0 ]
          then
            break
          else
            echo -e "\nKubernetes installation failed. Check internet connection. Retrying in 20 seconds.\n"
            sleep 20
          fi
        done

        echo "JOINNODE" > $STATE
    ;;

    JOINNODE)

        echo -e "\nJoining this Kubernetes Node to the Kubernetes Master."
        echo -e "You will be prompted to trust k8smaster.local, type 'yes', then type the password 'raspberry'\n"

        while : ;
        do
            bash -c "sudo $(ssh k8smaster.local 'cat ~/k8s-join-node.sh')"
            if [ $? -eq 0 ]
            then
                break
            else
                echo -e "\nKubernetes join failed. Try again.\n"
            fi
        done

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
sed --in-place '/~\/Raspberry-Pi-Kubernetes-Cluster-master\/scripts\/install-node.sh/d' ~/.bashrc

echo -e "\nFINISHED and ready for 'sudo kubeadm join'\n"