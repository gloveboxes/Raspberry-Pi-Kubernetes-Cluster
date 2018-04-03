# Raspberry Pi Optimisations and Utilities

## Pinning Raspberrypi-kernel

As at April 2nd, 2018 there is an issue with the raspberrypi-kernel/stable 1.20180328-1 armhf release of the kernel. Unsure what the issue but the kubernetes master would system would "kernel panic" and restart.

So as a temporary work around I pinned the upgrades that are prefixed raspberrypi.

I created a file called raspberry and added to the /etc/apt/preferences.d directory with the following contents.

```bash
cd /etc/apt/preferences.d && sudo nano raspberry
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


## GPG error: EXPKEYSIG 3746C208A7317B0F when updating packages

https://cloud.google.com/compute/docs/troubleshooting/known-issues#keyexpired

```bash
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
```


and you'll see that the files starting with raspberrypi are exluded from the upgrade candidate list.

## SD Card Optimisation

Reduce writes to the SD Card and increase IO performance by mapping the /tmp and /var/log directories to RAM. Note you will lose the contents of these directories on reboot.

```bash

echo "tmpfs /tmp  tmpfs defaults,noatime 0 0" | sudo tee -a /etc/fstab
echo "tmpfs /var/log  tmpfs defaults,noatime,size=16m 0 0" | sudo tee -a /etc/fstab


```

## Memory Optimisation

if using Raspberry Pi Lite (Headless) you can reduce the memory split between the GPU and the rest of the system down to 16mb.

```bash
sudo sh -c echo "cgroup_enable=cpuset cgroup_enable=memory" | sudo tee -a /boot/cmdline.txt
```


## Network Mapper

Scans network for active IP Addresses

```bash
$ sudo apt install nmap

$ nmap -sn 192.168.2.0/24
```

## Manage Raspberry Pi Cluster as one unit with Fabric

See [Welcome to Fabric](http://www.fabfile.org/) for more information.

Fabric is a Python (2.5-2.7) library and command-line tool for streamlining the use of SSH for application deployment or systems administration tasks.

It provides a basic suite of operations for executing local or remote shell commands (normally or via sudo) and uploading/downloading files, as well as auxiliary functionality such as prompting the running user for input, or aborting execution.

### Sample fabfile.py 

```py
from fabric.api import *

env.hosts = [
  'pi@192.168.2.1',
  'pi@k8snode1.local',
  'pi@k8snode2.local',
  'pi@k8snode3.local',
  'pi@k8snode4.local'
]

env.password = 'raspberry'

@parallel
def cmd(command):
  sudo(command)
```

to execute ensure fabfile.py in path or current directory

```bash
$ fab cmd:"sudo reboot"
```