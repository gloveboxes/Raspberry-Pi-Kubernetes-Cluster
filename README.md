# Part 1: Raspberry Pi Kubernetes Cluster - Intelligence on the Edge

|Author|[Dave Glover, Microsoft Australia](https://developer.microsoft.com/en-us/advocates/dave-glover)|
|----|---|
|Platform| Raspberry Pi, Raspbian Buster, Kernel 4.19|
|Date|October 2019|
| Acknowledgements | Inspired by [Alex Ellis' work with his Raspberry Pi Zero Docker Cluster](https://blog.alexellis.io/visiting-pimoroni/) |
|Skill Level| This guide assumes you have some Raspberry Pi and networking experience. |

## Raspberry Pi Kubernetes Cluster

This guide targets building a Raspberry Pi Kubernetes cluster on Raspbian Buster (Debian 10 based).  

I wanted to refresh my Kubernetes skills and what better way to do this than to build a Raspberry Pi Kubernetes Cluster for Intelligent Edge projects.

It is a very capable system, and for now I have tested with [Azure Functions](https://azure.microsoft.com/en-au/services/functions?WT.mc_id=github-blog-dglover) written in Python and C#, [Azure Custom Vision](https://azure.microsoft.com/en-au/services/cognitive-services/custom-vision-service?WT.mc_id=github-blog-dglover) Machine Learning models, and [NGINX](https://www.nginx.com/) Web Server.


![Raspberry Pi Kubernetes Cluster](https://raw.githubusercontent.com/gloveboxes/RaspberryPiKubernetesCluster/master/Resources/rpi-kube-cluster.jpg)

It will soon be running [Azure IoT Edge on Kubernetes](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-install-iot-edge-kubernetes) and looking forward to firing up the recently announced [dapr.io](https://dapr.io?WT.mc_id=github-blog-dglover) event-driven, portable runtime for building microservices on cloud and edge.

This project forms part of a three part **Intelligence on the Edge** series. The followup topics will include:

* Bringing Python and .NET [Azure Functions](https://azure.microsoft.com/en-au/services/functions?WT.mc_id=github-blog-dglover) and [Azure Custom Vision](https://azure.microsoft.com/en-au/services/cognitive-services/custom-vision-service?WT.mc_id=github-blog-dglover) Machine Learning models to the Edge. Including Pod placement and working with hardware.
* Deploying and managing Intelligence on the Edge with Azure IoT Edge on Kubernetes.


## System Configuration

The Kubernetes Master and Node installation is fully scripted, and along with Kubernetes itself, the following services are are installed and configured:

1. [Flannel](https://github.com/coreos/flannel) Container Network Interface (CNI) Plugin.
2. [MetalLb](https://metallb.universe.tf/) LoadBalancer. MetalLB is a load-balancer implementation for bare metal Kubernetes clusters, using standard routing protocols.
3. [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/).
4. [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) Storage on NFS.
5. NFS Server (running on Kubernetes Cluster Node 1).
6. NGINX Web Server.

## Parts List

The following list assumes a Kubernetes cluster built with a minimum of three Raspberry Pis.

|Items||
|-----|----|
| 1 x Raspberry Pi for Kubernetes Master.<br/><ul><li>I used a Raspberry 3B Plus, I had one spare, it has dual band WiFi, and Gigabit Ethernet over USB 2.0 port (300Mbps), fast enough.</li></ul><br/>2 x Raspberry Pis for Kubernetes Nodes<ul><li>I used two Raspberry Pi 4 4GBs.</li><li>Raspberry Pi 4s make great Kubernetes Nodes, but Raspberry Pi 3s and 2s work very well too.</li></ul> | ![rpi4](Resources/rpi4.png)
|3 x SD Cards, one for each Raspberry Pi in the cluster.<ul><li>Minimum 16GB, recommend 32GB</li><li>Can be smaller if you intend to run the Kubernetes Nodes from USB3 SSD.</li><li>Unsure what SD Card to buy, then check out these [SD Card recommendations](https://www.androidcentral.com/best-sd-cards-raspberry-pi-4)</li></ul> | ![](Resources/sd-cards.png) |
|3 x Power supplies, one for each Raspberry Pi.|![](resources/power-supply.jpg)|
|1 x Network Switch [Dlink DGS-1005A](https://www.dlink.com.au/home-solutions/DGS-1005A-5-port-gigabit-desktop-switch) or similar| ![network switch](Resources/switch.png) |
|3 x Ethernet Patch Cables (I used 25cm patch cables to reduce clutter.) | ![patch cables](Resources/patch-cable.jpg)|
|Optional: 1 x [Raspberry Pi Rack](https://www.amazon.com.au/gp/product/B013SSA3HA/ref=ppx_yo_dt_b_asin_title_o02_s00?ie=UTF8&psc=1) or similar | ![raspberry pi rack](Resources/rack.jpg) |
|Optional: 2 x [Pimoroni Blinkt](https://shop.pimoroni.com/products/blinkt) RGB Led Strips. The BlinkT LED Strip can be a great way to visualize pod activity. | ![blinlt](Resources/blinkt.jpg).|
|Optional: 2 x USB3 SSDs for Kubernetes Nodes, or similar, ie something small. Installation script sets up Raspberry Pi Boot from USB3 SSD. Note, these are [SSD Enclosures](https://www.amazon.com.au/Wavlink-10Gbps-Enclosure-Aluminum-Include/dp/B07D54JH16/ref=sr_1_8?keywords=usb+3+ssd&qid=1571218898&s=electronics&sr=1-8), you need the M.2 drives as well.| ![usb3 ssd](Resources/usb-ssd.jpg) |

## Flashing Raspbian Buster Lite Boot SD Cards

I strongly recommend building your Kubernetes cluster on Raspbian Buster Lite. Raspbian Lite is headless, takes less space, and leaves more resources available for your applications. You must enable **SSH** for each SD Card, and add a **WiFi profile** for the Kubernetes Master SD Card.

There are plenty of guides for flashing Raspbian Lite SD Cards. Here are a couple of useful references:

* [Setting up a Raspberry Pi headless](https://www.raspberrypi.org/documentation/configuration/wireless/headless.md)
* If you've not set up a Raspberry Pi before then this is a great guide. ["HEADLESS RASPBERRY PI 3 B+ SSH WIFI SETUP (MAC + WINDOWS)"](https://desertbot.io/blog/headless-raspberry-pi-3-bplus-ssh-wifi-setup). The Instructions outlined for macOS will work on Linux.

### Summary of Installation Process

1. Using [balena Etcher](https://www.balena.io/etcher/), flash 3 x SD Cards with [Raspbian Buster Lite](https://www.raspberrypi.org/downloads/raspbian/)
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

![](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/network.png)

## Naming Conventions Used

1. The Kubernetes Master will be named **k8smaster.local**
2. The Kubernetes Nodes will be named **k8snode1..n**

## Kubernetes Master Installation

![](Resources/k8s-master.png)

### Installation Process

Ensure the Raspberry Pi to be configured as a Kubernetes Master is:

1. Connected by **Ethernet** to the **Network Switch**, and the **Network Switch** is power on.
2. The **WiFi Router** is in range and powered on.

#### Step 1: Connect to the Raspberry Pi to be Configured as the Kubernetes Master

1. From your desktop computer, start a SSH Session to the Raspberry Pi. `ssh pi@raspberrypi.local`.

#### Step 2: Start the Installation Process

1. Run the following command from the SSH terminal you started in step 1.

```bash
bash -c "$(curl https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/setup.sh)"
```

2. Select **M**aster set up.

#### Step 2: Configure Prerequisites

1. Various optimizations/prerequisites set (tmpfs, GPU memory, 64bit kernel enabled, swap diabled, cgroups for k8s, iptables set to legacy mode)
2. Network settings configured (Static address for eth0, and packet routing defined)
3. DHCP Server installed
4. The Raspberry Pi will be renamed to **k8smaster**
5. The Raspberry Pi is rebooted.

#### Step 3: Docker Installation

1. Reconnect to the Raspberry Pi as `ssh pi@k8smaster.local`
2. Docker is installed
3. The Raspberry Pi is rebooted.

#### Step 4: Kubernetes Installation

1. Reconnect to the Raspberry Pi as `ssh pi@k8smaster.local`
2. The installation will restart
3. Kubernetes will be installed

#### Step 5: Kubernetes Master Configuraton

1. [Flannel CNI](https://kubernetes.io/docs/concepts/cluster-administration/networking/#the-kubernetes-network-model) (Cluster Networking) installation
2. [MetalLB LoadBalance](https://metallb.universe.tf/) installation
3. [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) installation and configured for [admin access](https://medium.com/@kanrangsan/creating-admin-user-to-access-kubernetes-dashboard-723d6c9764e4)

#### Step 6: Kubernetes Node Join Token Created

1. A Kubernetes Node Join token is created and saved to _~/k8s-join-token_ on the Kubernetes Master. You will need this token to join new Kubernetes Nodes to the Master.

## Kubernetes Node Installation

Ensure the k8smaster and the Raspberry Pi that will be the first Kubernetes node are powered on and connected to the Network Switch. The DHCP Server running on the k8smaster will allocate an IP Address to the Raspberry Pi that will be the Kubernetes node.

![](Resources/k8s-first-node.png)

### Installation Process

Ensure the Raspberry Pi to be configured as a Kubernetes Node is connected by **Ethernet** to same the **Network Switch** the Kubernetes Master is connected to.

Power on the Raspberry Pi, and IP Address will be allocated from the DHCP Server running in the Kubernetes Master you just configured.

Repeat for each Raspberry Pi that you intent to be Kubernetes Nodes.

#### Step 1: Connect to the Raspberry Pi to be Configured as a Node

1. From your desktop computer, start a SSH Session to the k8smaster. `ssh pi@k8smaster.local`.
2. From the SSH Session you just started to the k8smaster device start another session to Raspberry Pi to be configured as a Kubernetes Node. `ssh pi@raspberry.local`
3. Remove any existing known host reference to raspberrypi.local `ssh-keygen -f "/home/pi/.ssh/known_hosts" -R "raspberrypi.local"`

#### Step 2: Start the Installation Process

1. Run the following command from the SSH terminal you started in step 1.

```bash
bash -c "$(curl https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/setup.sh)"
```

2. Select **Node** set up.

#### Step 3: Number the Kubernetes Node

You will be prompted to number the Kubernetes Node. Number from 1 to n, where n is the number of Kubernetes Nodes you plan to provision.

#### Step 4: Enable Boot from USB3 SSD

Is you have USB3 attached SSD Storage then select this option. The installation script assumes the USB SSD Drive is located at **/dev/sda**. The scripts starts **fdisk**, you need to create a clean disk partition. Follow these steps:

1. p to display existing disk partition
2. d to delete existing partitions
3. n to create a new partition, create a new primary partition, and take the rest of the defaults.
4. w to write new partition table
5. **fdisk** will close and the SSD dive with be formated and the SD Root root drive copied and the **cmdline.txt** patched to boot from SSD.

This requires a reboot, log back in after the reboot and the installation will continue.

#### Step 5: Update the Raspberry Pi Operating System

Recommend yes. The Raspberry Pi will reboot on completion. Log back in after the reboot and the installation will continue.

#### Step 6: Install Pimoroni Fan SMIM Support

Recommend an active cooling system for the Raspberry Pi 4. I like the [Pimoroni Fan SMIM](https://shop.pimoroni.com/products/fan-shim) If you have one fitted to your Raspbeery Pi 4 then select **yes** to install.

#### Step 7: Perquisites are installed and configured

No user action required

#### Step 8: Docker Installation

No user action required. This requires a reboot, log back in after the reboot and the installation will continue.

#### Step 9: Kubernetes Installation

No user action required

#### Step 10: Join new node to the Kubernetes Cluster

When you created the Kubernetes Master the node join command is displayed. `**kubeadm join 192.168.100.1:6443 --token ... --discovery-token-ca-cert-hash ...**`. You need to run this command to join the node to the cluster.

```bash
sudo kubeadm join 192.168.100.1:6443 --token ... --discovery-token-ca-cert-hash ...
```

## Static Route to the Kubernetes Cluster Subnet

1. The Kubernetes Cluster runs isolated on the **Network Switch** and operates on subnet 192.168.100.0/24.
2. A static route needs to be configured either on the **Network Router** (or on your computer) to define the entry point (gateway) into the Cluster subnet (192.168.100.0/24).
3. The gateway into the cluster is the IP Address of the WiFi adapter on the Kubernetes Master Raspberry Pi. In the following diagram the gateway into the cluster is the address allocated by the **Network Router** to the Kubernetes Master WiFi adapter which is 192.168.0.55.

Most **Network Routers** allow you to configure a static router. The following is an example configured on a Linksys Router.

![](resources/static-route-linksys.png)

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

## Installing kubectl on your Desktop Computer

1. [Install and Set Up kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
2. Open a terminal window on your desktop computer
3. Change directory to your home directory
    * macOS, Linux, and Windows Powershell `cd ~/`, Windows Command Prompt `cd %USERPROFILE%`
4. Copy Kube Config from **k8smaster.local**

    ```bash
    scp -r pi@k8smaster.local:~/.kube .kube
    ```

## Kubernetes Dashboard

### Step 1: Create Dashboard Access Token

This assumes you have installed **kubectl** and copied .kube config file to your desktop computer. 

```bash
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```

### Step 2: Start the Kubernetes Proxy

On Desktop computer, in a terminal window start the Kubernetes Proxy

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

    ![persistent storage](Resources/nfs-server.png)

## Useful Commands

### List DHCP Leases

```bash
dhcp-lease-list
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

# https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client
# https://github.com/kubernetes-incubator/external-storage/blob/master/nfs-client/deploy/deployment-arm.yaml