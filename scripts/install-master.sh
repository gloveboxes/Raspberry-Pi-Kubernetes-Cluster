#!/bin/bash

STATE=~/.KubeMasterInstallState
RUNNING=true

sed --in-place '/~\/Raspberry-Pi-Kubernetes-Cluster-master\/scripts\/install-master.sh/d' ~/.bashrc
echo "~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/install-master.sh" >> ~/.bashrc

echo -e "\n\nThis is a mult-stage installer.\nSome stages require a reboot.\nInstallation will automatically restart.\n\n"

while $RUNNING; do
  case $([ -f $STATE ] && cat $STATE) in

    INIT)

        while true; do
          echo ""
          read -p "Enable 64 Bit Kernel (Raspberry Pi 3 or better)? ([Y]es, [N]o): " kernel64bit
          case $kernel64bit in
            [Yy]* ) break;;
            [Nn]* ) break;;
            * ) echo "Please answer [Y]es, or [N]o).";;
          esac
        done

        if [ $kernel64bit = 'Y' ] || [ $kernel64bit = 'y' ]; then  
          echo -e "\nEnabling 64 Bit Linux Kernel\n" 
          echo "arm_64bit=1" | sudo tee -a /boot/config.txt > /dev/null
        fi

        # Network set up, set up packet passthrough
        ./setup-networking.sh

        # DHCP Server install and initialise
        ./install-dhcp-server.sh

        echo -e "\nSetting iptables to legacy mode - patch required for Kubernetes on Debian 10\n"

        # Set iptables in legacy mode - required for Kube compatibility
        # https://github.com/kubernetes/kubernetes/issues/71305
        sudo update-alternatives --set iptables /usr/sbin/iptables-legacy > /dev/null
        sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy > /dev/null

        echo -e "\nDiabling Linux swap file - Required for Kubernetes\n"

        #disable swap
        sudo dphys-swapfile swapoff > /dev/null
        sudo dphys-swapfile uninstall > /dev/null
        sudo systemctl disable dphys-swapfile > /dev/null

        echo -e "\nSetting GPU Memory to minimum - 16MB\n"
        echo "gpu_mem=16" | sudo tee -a /boot/config.txt > /dev/null

        # Disable hdmi to reduce power consumption
        sudo sed -i -e '$i \/usr/bin/tvservice -o\n' /etc/rc.local

        echo -e "\nMoving /tmp and /var/log to tmpfs - reduce SD Card wear\n"

        # Disk optimisations - move temp to ram.
        # Reduce writes to the SD Card and increase IO performance by mapping the /tmp and /var/log directories to RAM. 
        # Note you will lose the contents of these directories on reboot.
        echo "tmpfs /tmp  tmpfs defaults,noatime 0 0" | sudo tee -a /etc/fstab > /dev/null
        echo "tmpfs /var/log  tmpfs defaults,noatime,size=30m 0 0" | sudo tee -a /etc/fstab > /dev/null

        echo -e "\nEnabling cgroup support for Kubernetes\n"
        # enable cgroups for Kubernetes
        sudo sed -i 's/$/ ipv6.disable=1 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt

        # perform system upgrade
        while : ;
        do
          echo -e "\nUpdating Operating System\n"
          sudo apt-get update > /dev/null && sudo apt-get install -y -qq bmon > /dev/null && sudo apt upgrade -y
          if [ $? -eq 0 ]
          then
            break
          else
            echo -e "\nSystem Update Failed. Check Internet connection. Retrying in 20 seconds."
            sleep 20
          fi        
        done
        echo "NFS" > $STATE

        echo -e "\nRenamed your Raspberry Pi Kubernetes Master to k8smaster.local\n"
        sudo raspi-config nonint do_hostname 'k8smaster'

        echo -e "\nThe system will reboot. Log back in as pi@k8smaster.local.\nSet up will automatically continue.\n"

        sudo reboot
    ;;

    NFS)
        
        # https://sysadmins.co.za/setup-a-nfs-server-and-client-on-the-raspberry-pi/
        # https://vitux.com/install-nfs-server-and-client-on-ubuntu/
        
        while : ;
        do
          echo -e "\nInstalling NFS Server on k8snode1 for use as Cluster Storage Class and Persistent Storage\n"
          sudo apt-get install -y nfs-kernel-server
          if [ $? -eq 0 ]
          then
            break
          else
            echo -e "\nnfs-kernel-server installation failed. Check Internet connection. Retrying in 20 seconds."
            sleep 20
          fi
        done

        # Make the nfs directory to be shared
        mkdir -p ~/nfsshare
        mkdir -p ~/nfsshare/nginx

        # Change ownership recurse
        sudo chown -R nobody:nogroup /home/pi/nfsshare
        # ‘777’ permission, everyone can read, write and execute the file, recurse
        sudo chmod -R 777 /home/pi/nfsshare
        echo "Hello, World!" > /home/pi/nfsshare/nginx/index.html

        # available to * (all) IP address on the cluster
        echo "/home/pi/nfsshare *(rw,async,no_subtree_check)" | sudo tee -a /etc/exports  > /dev/null
        echo "/home/pi/nfsshare/nginx *(rw,async,no_subtree_check)" | sudo tee -a /etc/exports  > /dev/null
 
        # reload exports
        sudo exportfs -ra

        # Restart the NFS Server
        sudo systemctl restart nfs-kernel-server

        # show what's being shared
        showmount -e localhost

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
        echo -e "\nThe system will reboot. Log back in as pi@k8smaster.local.\nSet up will automatically continue.\n"
        sudo reboot
     
    ;;

    KUBERNETES)

        # let the system settle before kicking off kube install
        sleep 4

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

        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
        
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

        # Preload the Kubernetes images
        echo -e "\nPulling Kubernetes Images - this will take a few minutes depending on network speed.\n"
        kubeadm config images pull

        echo -e "\nInitialising Kubernetes Master - This will take a few minutes. Be patient:)\n"

        # Set up Kubernetes Master Node
        sudo kubeadm init --apiserver-advertise-address=192.168.100.1 --pod-network-cidr=10.244.0.0/16 --token-ttl 0 --skip-token-print

        # make kubectl generally avaiable
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

        echo kubeadm token create --print-join-command) > ~/k8s-join-node.sh
        cat ~/k8s-join-node.sh

        echo -e "The Kubernetes Node join token is saved to ~/k8s-join-token for convenience.\n"
        echo -e "This may represent a security risk.\n"
        echo -e "Delete if not comfortable with this."

        echo "KUBESETUP" > $STATE

    ;;

    KUBESETUP)

      cd ~/Raspberry-Pi-Kubernetes-Cluster-master/kubesetup

      echo -e "\nInstalling Flannel\n"

      # Install Flannel
      echo -e "\n\nInstalling Flannel CNI\n"
      sudo sysctl net.bridge.bridge-nf-call-iptables=1
      kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

      # Install MetalLB LoadBalancer
      # https://metallb.universe.tf
      kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.1/manifests/metallb.yaml
      kubectl apply -f ./metallb/metallb.yml

      echo -e "\nInstalling MetalLB LoadBalancer\n"

      # Install Kubernetes Dashboard
      # https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
      # https://medium.com/@kanrangsan/creating-admin-user-to-access-kubernetes-dashboard-723d6c9764e4
      kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta4/aio/deploy/recommended.yaml
      kubectl apply -f ./dashboard/dashboard-admin-user.yml
      kubectl apply -f ./dashboard/dashboard-admin-role-binding.yml
      
      ## Simplifies getting Kubernetes Dashboard Token
      cp ~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/get-dashboard-token.sh ~/
      sudo chmod +x ~/get-dashboard-token.sh

      echo -e "\nInstalling Persistent Storage Support\n"

      ## Enable Persistent Storage
      kubectl apply -f ./persistent-storage/nfs-client-deployment-arm.yaml
      kubectl apply -f ./persistent-storage/storage-class.yaml

      ## Install nginx

      kubectl apply -f ./nginx/nginx-pv.yaml
      kubectl apply -f ./nginx/nginx-pv-claim.yaml
      kubectl apply -f ./nginx/nginx-deployment.yaml


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

cat ~/k8s-join-node.sh

echo -e "The Kubernetes Node join token is saved to ~/k8s-join-token for convenience.\n"
echo -e "This may represent a security risk.\n"
echo -e "Delete if not comfortable with this."

cd ~/
sed --in-place '/~\/Raspberry-Pi-Kubernetes-Cluster-master\/scripts\/install-master.sh/d' ~/.bashrc
