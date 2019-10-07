#!/bin/bash

# Patch for Pi Sense HAT on Raspbian Buster
sudo raspi-config nonint do_resolution 2 4
sudo sed -i 's/#hdmi_force_hotplug=1/hdmi_force_hotplug=1/g' /boot/config.txt

read -p "Name your Raspberry Pi (eg k8smaster, k8snode1, ...): " RPINAME
sudo raspi-config nonint do_hostname $RPINAME

sudo apt update 
sudo apt install bmon 
sudo upgrade -y

./networking.sh

sudo reboot