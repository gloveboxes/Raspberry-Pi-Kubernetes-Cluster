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



# Auto Mount External SSD Storage

Acknowledgments: This notes are a summary of [Attach USB storage to your Raspberry Pi](https://blog.alexellis.io/attach-usb-storage/). Read Alex's article for a full explaination.


## Step 1: Unmount Storage

It may be necessary to 'unmount' the storage if it auto loaded in the context of your session

## Step 2: Identify the drive 

```bash
$ lsblk
```

````
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda           8:0    0  118G  0 disk 
└─sda1        8:1    0  118G  0 part
mmcblk0     179:0    0 29.8G  0 disk 
├─mmcblk0p1 179:1    0 41.8M  0 part /boot
└─mmcblk0p2 179:2    0 29.8G  0 part /
````

The 'sda' disk is the external storage device.


## Step 3: Create the partitions

```bash
$ sudo fdisk /dev/sda
```

Use the following commands

1. o - wipe existing partitions
2. n - create new partition and take all the defaults
3. w - write the changes
4. q - to quit

## Step 4: Format the new partition

```bash
$ sudo fdisk -l /dev/sda
````

```
Device     Boot Start       End   Sectors  Size Id Type
/dev/sda1        2048 247463935 247461888  118G 83 Linux
```

```bash
$ sudo mkfs.ext4 -L SSDRIVE1 /dev/sda1
```

## Step 5: Create a mount-point

```bash
$ sudo mkdir /mnt/ssdrive1
```

## Step 6: Make it permanent


```bash
$ sudo nano /etc/fstab
```

Add the following line.


```
LABEL=SSDRIVE1  /mnt/ssdrive1               ext4    defaults,noatime,rw,nofail  0       1
```

**Note:** I wanted all users to have full permissions on the drive so it's also marked with the 'rw' property.

The tmpfs lines move temp and log directories to ram to reduce wear on the SD Card.

```
proc            /proc           proc    defaults          0       0
PARTUUID=ccccbc57-01  /boot           vfat    defaults          0       2
PARTUUID=ccccbc57-02  /               ext4    defaults,noatime  0       1
LABEL=SSDRIVE1  /mnt/ssdrive2               ext4    defaults,noatime,rw,nofail  0       1
# a swapfile is not a swap partition, no line here
#   use  dphys-swapfile swap[on|off]  for that
tmpfs /tmp  tmpfs defaults,noatime 0 0
tmpfs /var/log  tmpfs defaults,noatime,size=16m 0 0
```

## Step 6: Test

Reboot your Raspberry Pi. 


```bash
sudo reboot
```

## Step 7: Review Permissions

From the File Manager review the permissions of your SSD storage. From the permisions tab of the mount point '/mnt/ssdrive1' then 'anyone' should have all permissions'.

Alternatively from command line.

```bash
$ ls -l
```

The permission set should be as follows.

```
drwxrwxrwx  4 root root 4096 Apr  6 21:55 ssdrive1
```

If not then set the permissions.

```bash
sudo chmod -R 777 /mnt/ssdrive1/
```

See an explanation of [file permissions](https://www.maketecheasier.com/file-permissions-what-does-chmod-777-means/)

## Step 8: Pat yourself on the back


# Backing up Raspberry Pi SD Card

* [Backing up and Restoring your Raspberry Pi's SD Card](https://thepihut.com/blogs/raspberry-pi-tutorials/17789160-backing-up-and-restoring-your-raspberry-pis-sd-card)
* [How do you monitor the progress of dd?](https://askubuntu.com/questions/215505/how-do-you-monitor-the-progress-of-dd)

**Notes** 

1. Use 'pv' to provide backup progress information.
2. pv -s 32G signifies that the SD Card is 32GB and is used to estimate the copy time.





```bash
$ sudo apt install pv -y
$ sudo dd if=/dev/mmcblk0 | pv -s 32G  |dd of=~/rpi3plus.img
```