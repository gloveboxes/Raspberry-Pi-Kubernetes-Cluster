# Using a Pi 3 as a Ethernet to WiFi router

* Date: **March 2018**
* Operating System: **Raspbian Sketch**
* Kernel: **4.9**
* Acknowledgements: **This is based on the guide at [Using a Pi 3 as a Ethernet to WiFi router](https://medium.com/linagora-engineering/using-a-pi-3-as-a-ethernet-to-wifi-router-2418f0044819)**


```bash
$ sudo nano /etc/sysctl.conf
```


```
# Uncomment the next line to enable packet forwarding for IPv4
net.ipv4.ip_forward = 1
```


As you don’t want to reboot immediately, you can simply reload sysctl with

```bash
$ sudo sysctl -p
```

Run **man sysctl** for more information on this command.


## Set static address for Raspberry Pi running the DHCP Server


```bash
sudo nano /etc/dhcpcd.conf
```

```
# Example static IP configuration:
interface eth0
static ip_address=192.168.2.1/24
static domain_name_servers=8.8.8.8 8.8.4.4
```

Then reboot

```bash
sudo reboot now
```

## Install the DHCP Server

```bash
$ sudo apt-get install isc-dhcp-server
$ sudo service isc-dhcp-server stop
```

### Configure the DHCP to only serve on the Ethernet adapter

```
$ sudo nano /etc/default/isc-dhcp-server
```
We only want the DHCP Server to serve IP Addresses on the ethernet adapter (not the wifi)

Modify INTERFACESv4=""

```
INTERFACESv4="eth0"
```

### Configure the DHCP Server Options

```bash
sudo nano /etc/dhcp/dhcpd.conf
```

Scroll through file and replace sample #authoritative section.

```
#authoritative;

authoritative; # I will be the single DHCP server on this network, trust me authoritatively
# subnet and netmask matches what you've defined on the network interface

subnet 192.168.2.0 netmask 255.255.255.0 {
  interface eth0; # Maybe optional, I was not sure :o

  range 192.168.2.50 192.168.2.250; # Hands addresses in this range
  option broadcast-address 192.168.2.255; # Matches the broadcast address of the network interface
  option routers  192.168.2.1; # The IP address of the Pi
  option domain-name "kube8s.local"; # You can pick what you want here
  option domain-name-servers 8.8.8.8, 8.8.4.4; # Use your company DNS servers, or your home router, or any other DNS server
  default-lease-time 600;
  max-lease-time 7200;
}


```

## Routing traffic through the wireless interface

```bash
sudo iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o wlan0 -j MASQUERADE
```

### Persist the iptables

```bash
sudo apt install iptables-persistent
```

## DHCP IP Address Reservations

```bash
sudo nano /etc/dhcp/dhcpd.conf
```


```
host k8snode1 {
  hardware ethernet b8:27:eb:8f:ed:9a;
  fixed-address 192.168.2.10;
}

host k8snode2 {
  hardware ethernet b8:27:eb:f4:7d:66;
  fixed-address 192.168.2.11;
}

host k8snode3 {
  hardware ethernet b8:27:eb:a1:2f:52;
  fixed-address 192.168.2.12;
}

host k8snode4 {
  hardware ethernet b8:27:eb:39:61:6a;
  fixed-address 192.168.2.13;
}
```

### Restart the DHCP Server

```bash
sudo systemctl restart isc-dhcp-server.service 
```


### DHCP Service Commands

```bash
sudo systemctl start isc-dhcp-server.service 
sudo systemctl stop isc-dhcp-server.service
sudo systemctl restart isc-dhcp-server.service  
sudo systemctl status isc-dhcp-server.service 
```