# Azure Functions on a Raspberry Pi Kubernetes Cluster

![](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/network.png)

|Author|Dave Glover, Microsoft Australia|
|----|---|
|Platform| Raspberry Pi, Kernel 4.19|
|Date|October 2019|

## Parts List

## Installation

### Kubernetes Master Set Up

Installation Overview:

1. Renames the Raspberry Pi to k8smaste.local
2. Sets up networking including DHCP Server
3. Sets iptables to legacy mode for kubernetes compatibility
4. Disables swap file
5. Sets GPU memory to 16MB down from default of 64MB
6. Enables 64bit kernel
7. Sets cgroups for Kubernetes
8. Installs Docker
9. Installs Kubernetes
10. [Installs Flannel CNI](https://kubernetes.io/docs/concepts/cluster-administration/networking/#the-kubernetes-network-model) (Cluster Networking)
11. Installs [MetalLB LoadBalance](https://metallb.universe.tf/)

### MetalLB LoadBalance



### Kubernetes Node Set Up

## 

Log into the Raspberry Pi that will be the Kubernettes Master. Run the following command from the Raspberry SSH session:

## Kubernetes Cluster and Network Topology

```bash
bash -c "$(curl https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/setup.sh)"
```

## Kubernetes Dashboard

![Kubernetes Dashboard](https://raw.githubusercontent.com/gloveboxes/RaspberryPiKubernetesCluster/master/Resources/KubernetesDashboard.png)

## Raspberry Pi Cluster

![Raspberry Pi Kubernetes Cluster](https://raw.githubusercontent.com/gloveboxes/RaspberryPiKubernetesCluster/master/Resources/rpi-kube-cluster.jpg)
