# Using a Pi 3A/B Plus as a Ethernet to WiFi router

* Date: **August 2019**
* Operating System: **Raspbian Buster**
* Kernel: **4.19**
* Acknowledgements: **This is based on the guide at [Using a Pi 3 as a Ethernet to WiFi router](https://medium.com/linagora-engineering/using-a-pi-3-as-a-ethernet-to-wifi-router-2418f0044819)**, and **[Setting up a Raspberry Pi as a Wireless Access Point](https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md)**

## Raspberry Pi Device for Ethernet Access Point

The Raspberry Pi 3B Plus is a great candidate for an Ethernet Access Point as it have 2.4 and 5G wifi chip, plus a Gigabyte Ethernet port (Though not 100% Gigabyte throughput as it sits on USB2 bus).

## Raspbian Desktop

Recommend building Ethernet Access Point using Raspbian Desktop edition. This is handy if you need authenticate against a [Captive Portal](https://en.wikipedia.org/wiki/Captive_portal) as you use the browser in the Raspbian Desktop.

Be sure to enable **VNC** from **sudo raspi-config** interfaces menu. Install [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) on your desktop and connect to 192.168.2.1 for remote desktop access into the Raspberry Pi access point.

## SSH Authentication with private/public keys

![ssh login](resources/ssh-login.jpg)

### From Linux and macOS

1. Create your key. This is typically a one-time operation. **Take the default options**.

```bash
ssh-keygen -t rsa
```

2. Copy the public key to your Raspberry Pi.

```bash
ssh-copy-id pi@192.168.2.1
```

### From Windows

1. From PowerShell, create your key. This is typically a one-time operation. **Take the default options**

```bash
ssh-keygen -t rsa
```

2. From PowerShell, copy the public key to your Raspberry Pi

```bash
cat ~/.ssh/id_rsa.pub | ssh `
pi@192.168.2.1 `
"mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys"
```

## Disconnect Ethernet Cable

Ensure Ethernet cable is unplugged from Raspberry Pi as packet routing gets modified and it will cause install issues later in the script.

## Raspberry Pi Buster Lite Pi Sense HAT Patch

```bash
sudo raspi-config nonint do_resolution 2 4
sudo sed -i 's/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/g' /boot/config.txt
```

## Update Raspberry Pi and Reboot

```bash
sudo apt update && sudo apt upgrade -y && sudo reboot
```

## Enable Packet Forwarding for IPv4 and Restart Service

```bash
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf && \
sudo sysctl -p
```

## Set static address for Ethernet and restart DHCP Client

Append network configuration to the /etc/dhcpcd.conf.

```bash
echo 'interface eth0' | sudo tee -a /etc/dhcpcd.conf && \
echo 'static ip_address=192.168.100.1/24' | sudo tee -a /etc/dhcpcd.conf && \
echo 'noipv6' | sudo tee -a /etc/dhcpcd.conf && \
sudo reboot
```

## Install the DNS/DHCP Server

```bash
sudo apt-get install isc-dhcp-server && \
sudo service isc-dhcp-server stop
```

```bash
sudo nano /etc/default/isc-dhcp-server
```

```text
INTERFACESv4="eth0"
```

```bash
sudo nano /etc/dhcp/dhcpd.conf
```

Scroll through file and replace sample #authoritative section.

```bash
sudo cat <<EOT>> /etc/dhcp/dhcpd.conf
#authoritative;

authoritative; # I will be the single DHCP server on this network, trust me authoritatively
# subnet and netmask matches what you've defined on the network interface

subnet 192.168.100.0 netmask 255.255.255.0 {
  interface eth0; # Maybe optional, I was not sure :o

  range 192.168.100.50 192.168.100.100; # Hands addresses in this range
  option broadcast-address 192.168.100.255; # Matches the broadcast address of the network interface
  option routers  192.168.100.1; # The IP address of the Pi
  option domain-name "kube8s.local"; # You can pick what you want here
  option domain-name-servers 8.8.8.8, 8.8.4.4; # Use your company DNS servers, or your home router, or any other DNS server
  default-lease-time 600;
  max-lease-time 7200;
}
EOT
```

## Reboot

```bash
sudo reboot
```

## Routing traffic through the wireless interface, and persist

```bash
sudo iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o wlan0 -j MASQUERADE && \
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat" && \
sudo sed -i -e '$i \iptables-restore < /etc/iptables.ipv4.nat\n' /etc/rc.local
```

## Turn off WiFi Power Management

For more stable/consistent WiFi performance turn off power management.

Update /etc/rc.local for start on boot and turn off power management now.

```bash
sudo sed -i -e '$i \iwconfig wlan0 power off\n' /etc/rc.local && \
sudo iwconfig wlan0 power off
```

## One script to rule them all

Copy and paste into Raspberry Pi SSH Terminal

```
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf && \
sudo sysctl -p && \
echo 'interface eth0' | sudo tee -a /etc/dhcpcd.conf && \
echo 'static ip_address=192.168.2.1/24' | sudo tee -a /etc/dhcpcd.conf && \
echo 'static domain_name_servers=8.8.8.8 8.8.4.4' | sudo tee -a /etc/dhcpcd.conf && \
echo 'noipv6' | sudo tee -a /etc/dhcpcd.conf && \
sudo service dhcpcd restart && \
sleep 5 && \
sudo apt-get install -y dnsmasq && \
sudo systemctl stop dnsmasq && \
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig && \
echo 'interface=eth0' | sudo tee -a /etc/dnsmasq.conf && \
echo 'dhcp-range=192.168.2.10,192.168.2.100,255.255.255.0,24h' | sudo tee -a /etc/dnsmasq.conf && \
sudo systemctl start dnsmasq && \
sudo iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o wlan0 -j MASQUERADE && \
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat" && \
sudo sed -i -e '$i \iptables-restore < /etc/iptables.ipv4.nat\niwconfig wlan0 power off\n' /etc/rc.local && \
sudo iwconfig wlan0 power off
```

## DHCP Server  Commands

```bash
sudo systemctl status dnsmasq
```

## Useful Tools

### Network Mapper

Scans network for active IP Addresses

```bash
$ sudo apt install nmap

$ nmap -sn 192.168.2.0/24
```