# Setting up a Raspberry Pi Kubernetes Cluster

|Author|Dave Glover, Microsoft Australia|
|----|---|
|Platform| Raspberry Pi, Kernel 4.19|
|Date|October 2019|

1. [Raspberry Pi Optimisations](raspisetup.md)
1. [Using a Pi 3 as a Ethernet to WiFi router](wifirouter.md)
2. [Setting up Kubernetes Cluster](kubecluster.md)

## Raspberry Pi Cluster

![Raspberry Pi Kubernetes Cluster](https://raw.githubusercontent.com/gloveboxes/RaspberryPiKubernetesCluster/master/Resources/RaspberryPiKubernetesCluster.jpg)

## Installer

Log into the Raspberry Pi that will be the Kubernettes Master. Run the following command from the Raspberry SSH session:

```bash
bash -c "$(curl https://raw.githubusercontent.com/gloveboxes/Raspberry-Pi-Kubernetes-Cluster/master/setup.sh)"
```

## Kubernetes Dashboard

![Kubernetes Dashboard](https://raw.githubusercontent.com/gloveboxes/RaspberryPiKubernetesCluster/master/Resources/KubernetesDashboard.png)