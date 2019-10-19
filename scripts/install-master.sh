#!/bin/bash

STATE=~/.KubeMasterInstallState
RUNNING=true

sed --in-place '/~\/Raspberry-Pi-Kubernetes-Cluster-master\/scripts\/install-master.sh/d' ~/.bashrc
echo "~/Raspberry-Pi-Kubernetes-Cluster-master/scripts/install-master.sh" >> ~/.bashrc

echo -e "\n\nThis is a mult-stage installer.\nSome stages require a reboot.\nInstallation will automatically restart.\n\n"

while $RUNNING; do
  case $([ -f $STATE ] && cat $STATE) in

    INIT)

        echo -e "\nUpdating and installing utilities\n"

        sudo apt-get update >/dev/null && sudo apt-get install -y -qq bmon >/dev/null

        # Network set up, set up packet passthrough
        ./setup-networking.sh

        # DHCP Server install and initialise
        ./install-dhcp-server.sh

        echo -e "\nSetting iptables to legacy mode - patch required for Kubernetes on Debian 10\n"

        # Set iptables in legacy mode - required for Kube compatibility
        # https://github.com/kubernetes/kubernetes/issues/71305
        sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
        sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

        echo -e "\nDiabling Linux swap file - Required for Kubernetes\n"

        #disable swap
        sudo dphys-swapfile swapoff
        sudo dphys-swapfile uninstall
        sudo systemctl disable dphys-swapfile

        echo -e "\nSetting GPU Memory to minimum - 16MB\n"
        echo -e "\nEnabling 64 Bit Linux Kernel\n"

        echo "gpu_mem=16" | sudo tee -a /boot/config.txt
        echo "arm_64bit=1" | sudo tee -a /boot/config.txt

        echo -e "\nMoving /tmp and /var/log to tmpfs - reduce SD Card wear\n"

        # Disk optimisations - move temp to ram.
        # Reduce writes to the SD Card and increase IO performance by mapping the /tmp and /var/log directories to RAM. 
        # Note you will lose the contents of these directories on reboot.
        echo "tmpfs /tmp  tmpfs defaults,noatime 0 0" | sudo tee -a /etc/fstab && \
        echo "tmpfs /var/log  tmpfs defaults,noatime,size=30m 0 0" | sudo tee -a /etc/fstab

        echo -e "\nEnabling cgroup support for Kubernetes\n"
        # enable cgroups for Kubernetes
        sudo sed -i 's/$/ ipv6.disable=1 cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1/' /boot/cmdline.txt

        echo -e "\nUpdating Operating System\n"
        # perform system upgrade
        sudo apt-get dist-upgrade -y -qq >/dev/null

        echo "DOCKER" > $STATE

        echo -e "\nRenamed your Raspberry Pi Kubernetes Master to k8smaster.local\n"
        sudo raspi-config nonint do_hostname 'k8smaster'

        echo -e "\nThe system will reboot. Log back in as pi@k8smaster.local.\nSet up will automatically continue.\n"

        sudo reboot
    ;;

    DOCKER)
        echo -e "\nInstalling Docker\n"
        # Install Docker
        curl -sSL get.docker.com | sh && sudo usermod $USER -aG docker

        echo "KUBERNETES" > $STATE
        echo -e "\nThe system will reboot. Log back in as pi@k8smaster.local.\nSet up will automatically continue.\n"
        sudo reboot        
    ;;

    KUBERNETES)
        echo -e "\nInstalling Kubernetes\n"

        # let the system settle before kicking off kube install
        sleep 10

        # Install Kubernetes
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        sudo apt-get update -qq >/dev/null
        sudo apt-get install -qq -y kubeadm >/dev/null

        # Preload the Kubernetes images
        echo -e "\nPulling Kubernetes Images - this will take a few minutes depending on network speed.\n"
        kubeadm config images pull

        echo -e "\nInitialising Kubernetes Master - This will take a few minutes. Be patient:)\n"
        echo -e "\nYou will need to make a note of the Kubernetes kubeadm join token displayed as part of the initialisation process:)\n"

        # Set up Kubernetes Master Node
        sudo kubeadm init --apiserver-advertise-address=192.168.100.1 --pod-network-cidr=10.244.0.0/16 --token-ttl 0

        # make kubectl generally avaiable
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config

        echo -e "\nYou will need to make a note of the Kubernetes kubeadm join token displayed as part of the initialisation process:)\n"

        kubeadm token list

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

      echo -e "\nInstalling Persistent Storage Support\n"

      ## Enable Persistent Storage
      kubectl apply -f ./persistent-storage/nfs-client-deployment-arm.yaml
      kubectl apply -f ./persistent-storage/storage-class.yaml
      kubectl apply -f ./persistent-storage/persistent-volume.yaml
      kubectl apply -f ./persistent-storage/persistent-volume-claim.yaml
      kubectl apply -f ./persistent-storage/nginx-test-pod.yaml


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

cd ~/

sed --in-place '/~\/Raspberry-Pi-Kubernetes-Cluster-master\/scripts\/install-master.sh/d' ~/.bashrc
