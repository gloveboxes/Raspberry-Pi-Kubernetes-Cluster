#!/bin/bash
echo -e "\nEnabling boot from USB3 Drive\n"

BOOT_USB3=false

while :
do
    BOOT_USB3=false
    echo 

    lsblk 
    echo
    echo -e "\nListed are all the available block devices\n"
    echo -e "This script assumes only ONE USB Drive is connected to the Raspberry Pi at /dev/sda"
    echo -e "This script will DELETE ALL existing partitions on the USB drive at /dev/sda"
    echo -e "A new primary partition is created and formated at /dev/sda1\n"

    read -p "Do you wish to create a bootable USB drive on device /dev/sda? ([Y]es, [N]o): " response 

    case $response in
    [Yy]* ) BOOT_USB3=true; break;;
    [Nn]* ) break;;
    * ) echo "Please answer [Y]es, or [N]o).";;
    esac
done


if [ "$BOOT_USB3" = true ]; then

    sudo sfdisk --delete /dev/sda
    echo 'type=83' | sudo sfdisk /dev/sda
    sudo sfdisk -d /dev/sda

    sudo mkfs.ext4 /dev/sda1
    sudo mkdir /media/usbdrive
    sudo mount /dev/sda1 /media/usbdrive
    sudo rsync -avx / /media/usbdrive
    sudo sed -i '$s/$/ root=\/dev\/sda1 rootfstype=ext4 rootwait/' /boot/cmdline.txt

fi

sudo reboot
