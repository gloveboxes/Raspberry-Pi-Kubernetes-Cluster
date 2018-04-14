# Setting up a Raspberry Pi Kubernetes Cluster


** These notes are "work in progress"**


## Pinning Raspberrypi-kernel

As at April 2nd, 2018 there is an issue with the raspberrypi-kernel/stable 1.20180328-1 armhf release of the kernel. Unsure what the issue but the kubernetes master would repeatedly "kernel panic" and restart.

So as a temporary work around I've pinned the upgrades that are prefixed raspberrypi.

To pin upgrades create a file in the /etc/apt/preferences.d directory with the following contents.

```bash
$ cd /etc/apt/preferences.d && sudo nano raspberry
```

```
Package: raspberrypi*       
Pin: release *
Pin-Priority: -5
```

save and rerun the apt upgrade process which will exclude the kernel updates.

```bash
sudo apt update && sudo apt list --upgradable && sudo apt dist-upgrade -y
```


Cluster up and running:)

* Date: **April 2018**
* Operating System: **Raspbian Sketch**
* Kernel: **4.9**

1. [Raspberry Pi Optimisations](raspisetup.md)
1. [Using a Pi 3 as a Ethernet to WiFi router](wifirouter.md)
2. [Setting up Kubernetes Cluster](kubecluster.md)





# Useful Resources


* [SSH Essentials: Working with SSH Servers, Clients, and Keys](https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys)

