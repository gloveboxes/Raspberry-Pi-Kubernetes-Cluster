# Setting up a Raspberry Pi Kubernetes Cluster



|Author|Dave Glover, Microsoft Australia|
|----|---|
|Platform| Raspberry Pi, Kernel 4.9|
|Date|April 2018|




1. [Raspberry Pi Optimisations](raspisetup.md)
1. [Using a Pi 3 as a Ethernet to WiFi router](wifirouter.md)
2. [Setting up Kubernetes Cluster](kubecluster.md)

## Raspberry Pi Cluster

![Raspberry Pi Kubernetes Cluster](https://raw.githubusercontent.com/gloveboxes/RaspberryPiKubernetesCluster/master/Resources/RaspberryPiKubernetesCluster.jpg)


## Kubernetes Nodes

```
pi@k8smaster:~ $ kubectl get nodes -o wide
NAME        STATUS     ROLES    AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME      k8s         Ready      <none>   55m   v1.16.0   192.168.0.132   <none>        Raspbian GNU/Linux 10 (buster)   4.19.75-v7+      docker://19.3.2        k8smaster   Ready      master   84m   v1.16.0   192.168.2.33    <none>        Raspbian GNU/Linux 10 (buster)   4.19.75-v7+      docker://19.3.2        k8snode1    NotReady   <none>   80m   v1.16.0   192.168.2.83    <none>        Raspbian GNU/Linux 10 (buster)   4.19.75-v7+      docker://19.3.2        k8snode2    Ready      <none>   79m   v1.16.0   192.168.2.22    <none>        Raspbian GNU/Linux 10 (buster)   4.19.75-v7+      docker://19.3.2        k8snode4    Ready      <none>   42m   v1.16.0   192.168.2.93    <none>        Raspbian GNU/Linux 10 (buster)   4.19.75-v7+      docker://19.3.2 
```



## Kubernetes Dashboard

![Kubernetes Dashboard](https://raw.githubusercontent.com/gloveboxes/RaspberryPiKubernetesCluster/master/Resources/KubernetesDashboard.png)