# Raspberry Pi Optimisations and Utilities

## SD Card Optimisation

Reduce writes to the SD Card and increase IO performance by mapping the /tmp and /var/log directories to RAM. Note you will lose the contents of these directories on reboot.

```bash
sudo cat <<EOT>> /etc/fstab
tmpfs /tmp  tmpfs defaults,noatime 0 0
tmpfs /var/log  tmpfs defaults,noatime,size=16m 0 0
EOT
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