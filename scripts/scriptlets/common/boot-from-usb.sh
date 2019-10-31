#!/bin/bash
echo -e "\nEnabling boot from USB Drive\n"

sudo sfdisk --delete /dev/sda

sleep 6

echo 'type=83' | sudo sfdisk /dev/sda

lsblk
sleep 6

sudo sfdisk -d /dev/sda

sudo mkfs.ext4 /dev/sda1

lsblk
sleep 6

sudo mkdir /media/usbdrive
sudo mount /dev/sda1 /media/usbdrive
sudo rsync -avx / /media/usbdrive
sudo sed -i '$s/$/ root=\/dev\/sda1 rootfstype=ext4 rootwait/' /boot/cmdline.txt

sudo reboot
