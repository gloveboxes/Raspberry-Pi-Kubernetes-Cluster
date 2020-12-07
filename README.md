# Part 1: Building a Kubernetes "Intelligent Edge" Cluster on Raspberry Pi

![Raspberry Pi Kubernetes Cluster](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/rpi-kube-cluster.jpg)

|Author|[Dave Glover, Microsoft Australia](https://developer.microsoft.com/advocates/dave-glover?WT.mc_id=iot-0000-dglover)|
|----|---|
|Platform| Raspberry Pi, Raspbian Buster, Kernel 4.19|
|Date|Updated May 2020|
| Acknowledgments | Inspired by [Alex Ellis' work with his Raspberry Pi Zero Docker Cluster](https://blog.alexellis.io/visiting-pimoroni/) |
|Skill Level| This guide assumes you have some Raspberry Pi and networking experience. |

## Building a Raspberry Pi Kubernetes Cluster

Building a Kubernetes Intelligent Edge cluster on Raspberry Pi is a great learning experience, a stepping stone to building robust Intelligent Edge solutions, and an awesome way to impress your friends. Skills you develop on the _edge_ can be used in the _cloud_ with [Azure Kubernetes Service](https://azure.microsoft.com/services/kubernetes-service/?WT.mc_id=iot-0000-dglover).

### Learning Kubernetes

You can download a free copy of the [Kubernetes: Up and Running, Second Edition](https://azure.microsoft.com/resources/kubernetes-up-and-running/?WT.mc_id=iot-0000-dglover) book. It is an excellent introduction to Kubernetes and it will accelerate your understanding of Kubernetes.

![](Resources/kubernetes-up-and-running.png)

Published: 8/22/2019

Improve the agility, reliability, and efficiency of your distributed systems by using Kubernetes. Get the practical Kubernetes deployment skills you need in this O’Reilly e-book. You’ll learn how to:

* Develop and deploy real-world applications.

* Create and run a simple cluster.

* Integrate storage into containerized microservices.

* Use Kubernetes concepts and specialized objects like DaemonSet jobs, ConfigMaps, and secrets. 

Learn how to use tools and APIs to automate scalable distributed systems for online services, machine learning applications, or even a cluster of Raspberry Pi computers.

## Introduction

The Kubernetes cluster is built with Raspberry Pi 4 nodes and is very capable. It has been tested with Python and C# [Azure Functions](https://azure.microsoft.com/services/functions?WT.mc_id=iot-0000-dglover), [Azure Custom Vision](https://azure.microsoft.com/services/cognitive-services/custom-vision-service?WT.mc_id=iot-0000-dglover) Machine Learning models, and [NGINX](https://www.nginx.com/) Web Server.

This project forms the basis for a four-part _Intelligence on the Edge_ series. The followup topics will include:

* Build, debug, and deploy Python and C# [Azure Functions](https://azure.microsoft.com/services/functions?WT.mc_id=iot-0000-dglover) to a Raspberry Pi Kubernetes Cluster, and learn how to access hardware from a Kubernetes managed container.

* Developing, deploying and managing _Intelligence on the Edge_ with [Azure IoT Edge on Kubernetes](https://docs.microsoft.com/azure/iot-edge/how-to-install-iot-edge-kubernetes?WT.mc_id=iot-0000-dglover).

* Getting started with the [dapr.io](https://dapr.io?WT.mc_id=github-blog-dglover), an event-driven, portable runtime for building microservices on cloud and edge.

## System Configuration

![](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/network.png)

The Kubernetes Master and Node installations are fully scripted, and along with Kubernetes itself, the following services are installed and configured:

1. [Flannel](https://github.com/coreos/flannel) Container Network Interface (CNI) Plugin.
2. [MetalLb](https://metallb.universe.tf/) LoadBalancer. MetalLB is a load-balancer implementation for bare metal Kubernetes clusters, using standard routing protocols.
3. [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/).
4. [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) Storage on NFS.
5. NFS Server.
6. NGINX Web Server.

## Parts List

The following list assumes a Kubernetes cluster built with a minimum of three Raspberry Pis.

|Items||
|-----|----|
| 1 x Raspberry Pi for Kubernetes Master.<br/><ul><li>I used a Raspberry 3B Plus, I had one spare, it has dual-band WiFi, and Gigabit Ethernet over USB 2.0 port (300Mbps), fast enough.</li></ul><br/>2 x Raspberry Pis for Kubernetes Nodes<ul><li>I used two Raspberry Pi 4 4GBs.</li><li>Raspberry Pi 4s make great Kubernetes Nodes, but Raspberry Pi 3s and 2s work very well too.</li></ul> | ![rpi4](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/rpi4.png)
|3 x SD Cards, one for each Raspberry Pi in the cluster.<ul><li>Minimum 16GB, recommend 32GB. The new U3 Series from SanDisk is fast!</li><li>The SD Card can be smaller if you intend to run the Kubernetes Nodes from USB3.</li><li>Unsure what SD Card to buy, then check out these [SD Card recommendations](https://www.androidcentral.com/best-sd-cards-raspberry-pi-4)</li></ul> | ![](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/sd-cards.png) |
|3 x Power supplies, one for each Raspberry Pi.|![](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/power-supply.jpg)|
|1 x Network Switch [Dlink DGS-1005A](https://www.dlink.com.au/home-solutions/DGS-1005A-5-port-gigabit-desktop-switch) or similar| ![network switch](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/switch.png) |
|3 x Ethernet Patch Cables (I used 25cm patch cables to reduce clutter.) | ![patch cables](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/patch-cable.jpg)|
| Optional: If you using a Raspberry Pi 4 then recommend active cooling: Pimoroni [FanSHIM](https://shop.pimoroni.com/products/fan-shim) | ![FanSHIM](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/fan-shim.jpg) |
|Optional: 1 x [Raspberry Pi Rack](https://www.amazon.com.au/gp/product/B013SSA3HA/ref=ppx_yo_dt_b_asin_title_o02_s00?ie=UTF8&psc=1) or similar | ![raspberry pi rack](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/rack.jpg) |
|Optional: 2 x [Pimoroni Blinkt](https://shop.pimoroni.com/products/blinkt) RGB Led Strips. The BlinkT LED Strip can be a great way to visualize pod activity. | ![blinlt](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/blinkt.jpg)|
|Optional: 2 x USB3 Flash Drivers for Kubernetes Nodes, or similar. I would recommend the Samsung [USB 3.1 Flash Drive FIT Plus 128GB](https://www.samsung.com/us/computing/memory-storage/usb-flash-drives/usb-3-1-flash-drive-fit-plus-128gb-muf-128ab-am/). See the [5 of the Fastest and Best USB 3.0 Flash Drives](https://www.makeuseof.com/tag/5-of-the-fastest-usb-3-0-flash-drives-you-should-buy/). Installation script sets up Raspberry Pi Boot from USB3.| ![usb3 ssd](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/samsung-flash-128.png) |
|Optional: 2 x USB3 SSDs for Kubernetes Nodes, or similar, ie something small. Installation script sets up Raspberry Pi Boot from USB3 SSD. Note, these are [SSD Enclosures](https://www.amazon.com.au/Wavlink-10Gbps-Enclosure-Aluminum-Include/dp/B07D54JH16/ref=sr_1_8?keywords=usb+3+ssd&qid=1571218898&s=electronics&sr=1-8), you need the M.2 drives as well.| ![usb3 ssd](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/usb-ssd.jpg) |

## Flashing Raspbian Buster Lite Boot SD Cards

Build your Kubernetes cluster with Raspbian Buster Lite. Raspbian Lite is headless, takes less space, and leaves more resources available for your applications. You must enable **SSH** for each SD Card, and add a **WiFi profile** for the Kubernetes Master SD Card.

There are plenty of guides for flashing Raspbian Lite SD Cards. Here are a couple of useful references:

* Download [Raspbian Buster Lite](https://www.raspberrypi.org/downloads/).
* [Setting up a Raspberry Pi headless](https://www.raspberrypi.org/documentation/configuration/wireless/headless.md).
* If you've not set up a Raspberry Pi before then this is a great guide. ["HEADLESS RASPBERRY PI 3 B+ SSH WIFI SETUP (MAC + WINDOWS)"](https://desertbot.io/blog/headless-raspberry-pi-3-bplus-ssh-wifi-setup). The Instructions outlined for macOS will work on Linux.

### Creating Raspbian SD Card Boot Images

1. Using [balena Etcher](https://www.balena.io/etcher/), flash 3 x SD Cards with [Raspbian Buster Lite](https://www.raspberrypi.org/downloads/raspbian/). See the introduction to [Installing operating system images](https://www.raspberrypi.org/documentation/installation/installing-images/).
2. On each SD Card create an empty file named **ssh**, this enables SSH login on the Raspberry Pi.
    * **Windows:** From Powershell, open the drive labeled _boot_, most likely the _d:_ drive, and type `echo $null > ssh; exit`. From the Windows Command Prompt, open drive labeled _boot_, most like the _d:_ drive, and type `type NUL > ssh & exit`.
    * **macOS and Linux:** Open terminal from drive labeled _boot_, type `touch ssh && exit`.
3. On the Kubernetes Master SD Card, add a **wpa_supplicant.conf** file to the SD Card _boot_ drive with your WiFi Routers WiFi settings.

    ```text
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    update_config=1
    country=AU

    network={
        ssid="SSID"
        psk="WiFi Password"
    }
    ```

## Kubernetes Network Topology

The Kubernetes Master is also responsible for:

1. Allocating IP Addresses to the Kubernetes Nodes.
2. Bridging network traffic between the external WiFi network and the internal cluster Ethernet network.
3. NFS Services to support Kubernetes Persistent Storage.

![](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/network.png)

## Installation Script Naming Conventions

The following naming conventions are enforced in the installation scripts:

1. The Kubernetes Master will be named **k8smaster.local**
2. The Kubernetes Nodes will be named **k8snode1..n**

## Kubernetes Master Installation

![](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/k8s-master.png)

### Installation Process

Ensure the Raspberry Pi to be configured as a **Kubernetes Master** is:

1. Connected by **Ethernet** to the **Network Switch**, and the **Network Switch** is power **on**.
2. The **WiFi Router** is in range and powered on.
3. If rebuilding the Kubernetes Master then **disconnect** existing Kubernetes Nodes from the Network Switch as they can interfere with Kubernetes Master initialization.

#### Step 1: Start the Kubernetes Master Installation Process

1. Open a new terminal window from a macOS, Linux, or Windows Bash (Linux Subsystem for Windows).
2. Run the following command from the SSH terminal you started in step 1.
   > Note, as at July 2020 for [Raspberry Pi 3B and 3B+ CGroup support](https://github.com/raspberrypi/linux/issues/3644) is not included in the kernel. CGroups is required for Kubernetes. The workaround is to enable the 64bit kernel. You will be prompted to enable the 64Bit kernel. 

    ```bash
    bash -c "$(curl https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/setup.sh)"
    ```

3. Select **M**aster set up.

4. Configure Installation Options
    * Enable Boot from USB3 support
    <!-- * Enable 64bit Linux Kernel -->
    * Install [Pimoroni Fan SHIM](https://shop.pimoroni.com/products/fan-shim) Support

5. The automated installation will start. Note, the entire automated Kubernetes Master installation process is driven from your desktop computer.

## Kubernetes Node Installation

Ensure the k8smaster and all the Raspberry Pis that will be configured are **powered on** and connected to the **Network Switch**. The DHCP Server running on the k8smaster will allocate an IP Addresses to the Raspberry Pis to become the Kubernetes nodes.

![](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/kubernetes-nodes.png)

### Step 1: Connect to the newly configured Kubernetes Master

1. From your desktop computer, start an SSH Session to the k8smaster `ssh pi@k8smaster.local`

### Step 2: Start the Installation Process

1. Run the following command from the SSH terminal you started in step 1.
   > Note, as at July 2020 for [Raspberry Pi 3B and 3B+ CGroup support](https://github.com/raspberrypi/linux/issues/3644) is not included in the kernel. CGroups is required for Kubernetes. The workaround is to enable the 64bit kernel. You will be prompted to enable the 64Bit kernel. 

    ```bash
    bash -c "$(curl https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/setup.sh)"
    ```

2. Select **N**ode set up.

3. Configure Installation Options
    * Enable Boot from USB3 support
    <!-- * Enable 64bit Linux Kernel -->
    * Install [Pimoroni Fan SHIM](https://shop.pimoroni.com/products/fan-shim) Support


    <!-- * Enable Boot From USB -->

### Step 3: Review Devices

A list of devices found will be displayed. The devices display are those that have been allocated an IP Address by the DHCP Server running on the Kubernetes Master. Note, Kubernetes Nodes will only be installed on devices named _raspberrypi_.

```text
          HostName : IP Address
================================
       raspberrypi : 192.168.100.50
       raspberrypi : 192.168.100.51
```

Answer yes when all devices you wish to install Kubernetes on are displayed. The automated installation will now start.

## Setting up a Static Route to the Kubernetes Cluster

1. The Kubernetes Cluster runs isolated on the **Network Switch** and operates on subnet 192.168.100.0/24.
2. A static route needs to be configured either on the **Network Router** or on your computer to define the entry point (gateway) into the Cluster subnet (192.168.100.0/24).
3. The gateway IP Address is allocated by your **Network Router** to the Kubernetes Master WiFi adapter. In the above example, the Gateway address is 192.168.0.55.

Most **Network Routers** allow you to configure a static route. The following is an example configured on a Linksys Router.

![](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/static-route-linksys.png)

### Alternative: Set Local Static Route to Cluster Subnet (192.168.100.0/24)

If you don't have access to configure the Network Router you can set a static route on your local computer.

### Windows

From "Run as Administrator" Command Prompt

```bash
route add 192.168.100.0 mask 255.255.255.0 192.168.0.55
```

### macOS and Linux

**NOT WORKING RESEARCH SOME MORE**

```bash
route add -net 192.168.100.0 netmask 255.255.255.0 gw 192.168.0.55
```

### Troubleshooting Worker Node DNS issues

The Kubernetes master node network installation script sets the DNS servers used by the cluster to *domain-name-servers 8.8.8.8, 8.8.4.4* in */etc/dhcp/dhcpd.conf*. 

On company or managed networks querying these DNS servers may be blocked. If the default DNS addresses are blocked then the Kubernetes worker node installation will fail.

Update the domain-name-servers in the */etc/dhcp/dhcpd.conf* file to the IP addresses of your managed network DNS servers.

## Installing kubectl on your Desktop Computer

1. [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
2. Open a terminal window on your desktop computer
3. Change directory to your home directory
    * macOS, Linux, and Windows Powershell `cd ~/`, Windows Command Prompt `cd %USERPROFILE%`
4. Copy Kube Config from **k8smaster.local**

    ```bash
    scp -r pi@k8smaster.local:~/.kube ./
    ```

## Kubernetes Dashboard

### Step 1: Get the Dashboard Access Token

From the Windows Command Prompt (or PowerShell), macOS, or Linux Terminal, run the following command: 

Note, you will be prompted for the k8smaster.local password.

```bash
ssh pi@k8smaster.local ./get-dashboard-token.sh
```

### Step 2: Start the Kubernetes Proxy

On your Linux, macOS, or Windows computer, start a command prompt/terminal and start the Kubernetes Proxy.

```bash
kubectl proxy
```

### Step 3: Browse to the Kubernetes Dashboard

Click the following link to open the Kubernetes Dashboard. Select **Token** authentication, paste in the token you created from **Step 1** and connect.

**http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/overview?namespace=default** 

![Kubernetes Dashboard](https://raw.githubusercontent.com/gloveboxes/RaspberryPiKubernetesCluster/master/Resources/KubernetesDashboard.png)

## Kubernetes Cluster Persistence Storage

NFS Server installed on k8smaster.local

2. Installed and provisioned by Kubernetes Master installation script.
3. The following diagram describes how persistent storage is configured in the cluster.

    ![persistent storage](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/nfs-server.png)

## Useful Commands

### List DHCP Leases

```bash
dhcp-lease-list
```

### Switching Clusters

```bash
kubectl config get-contexts
kubectl config view
kubectl config current-context

kubectl config use-context pi3 or pi4
```

### Resetting Kubernetes Master or Node

````bash
sudo kubeadm reset && sudo systemctl daemon-reload && sudo systemctl restart kubelet.service
````

## References and Acknowledgements

1. Setting [iptables to legacy mode](https://github.com/kubernetes/kubernetes/issues/71305) on Raspbian Buster/Debian 10 for Kubernetes kube-proxy. Configured in installation scripts.

    ```bash
    sudo update-alternatives --set iptables /usr/sbin/iptables-legacy > /dev/null
    sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy > /dev/null
    ```
2. [Kubernetes Secrets](https://www.tutorialspoint.com/kubernetes/kubernetes_secrets.htm)

### Kubernetes Dashboard

1. [Kubernetes Web UI (Dashboard)](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
2. [Creating admin user to access Kubernetes dashboard](https://medium.com/@kanrangsan/creating-admin-user-to-access-kubernetes-dashboard-723d6c9764e4)

### Kubernetes Persistent Storage

1. [Kubernetes NFS-Client Provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client)
2. [kubernetes-incubator/external-storage](https://github.com/kubernetes-incubator/external-storage/blob/master/nfs-client/deploy/deployment-arm.yaml)

### NFS Persistent Storage

1. [Kubernetes NFS-Client Provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client)
2. [NFS Client Provisioner Deployment Template](https://github.com/kubernetes-incubator/external-storage/blob/master/nfs-client/deploy/deployment-arm.yaml)

### Flannel Cluster Networking

1. [Flannel CNI](https://kubernetes.io/docs/concepts/cluster-administration/networking/#the-kubernetes-network-model) (Cluster Networking) installation.

### MetalLB Load Balancer

1. [MetalLB LoadBalance](https://metallb.universe.tf/) installation.
