# Azure Functions on a Raspberry Pi Kubernetes Cluster

![](https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/Resources/network.png)

|Author|Dave Glover, Microsoft Australia|
|----|---|
|Platform| Raspberry Pi, Kernel 4.19|
|Date|October 2019|

## Installer

Log into the Raspberry Pi that will be the Kubernettes Master. Run the following command from the Raspberry SSH session:

## Kubernetes Cluster and Network Topology

```bash
bash -c "$(curl https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/setup.sh)"
```

## Kubernetes Dashboard

![Kubernetes Dashboard](https://raw.githubusercontent.com/gloveboxes/RaspberryPiKubernetesCluster/master/Resources/KubernetesDashboard.png)

## Raspberry Pi Cluster

![Raspberry Pi Kubernetes Cluster](https://raw.githubusercontent.com/gloveboxes/RaspberryPiKubernetesCluster/master/Resources/rpi-kube-cluster.jpg)