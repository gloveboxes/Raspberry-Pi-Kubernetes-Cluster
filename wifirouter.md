# Kubernetes Master Node Networking

* Date: **October 2019**
* Operating System: **Raspbian Buster**
* Kernel: **4.19**
* Acknowledgements: **This is based on the guide at [Using a Pi 3 as a Ethernet to WiFi router](https://medium.com/linagora-engineering/using-a-pi-3-as-a-ethernet-to-wifi-router-2418f0044819)**, and **[Setting up a Raspberry Pi as a Wireless Access Point](https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md)**

## Introduction

The Kubernetes Master node will also act as:

1. A DHCP Server, serving addresses to the Ethernet Switch attached Kubernetes nodes
2. Network packet switcher between Kebernetes Ethernet Nodes and WiFi external network.

<!-- Add diagram -->

## Disconnect Ethernet Cable

Ensure Ethernet cable is unplugged from Raspberry Pi as packet routing gets modified and it will cause install issues later in the script.

## Initialise System

1. Patch for Pi Sense HAT on Raspbian Buster
2. Rename system
3. Update system
4. Configure network
5. and reboot

```bash
./scripts/initialise.sh
```

## Install and configure DHCP Server

```bash
./scripts/dhcp-server.sh
```
