#!/bin/bash

echo "Installing dependencies..."
xbps-install -Sy parted curl xtools
echo ""
echo -e "\e[1;34mWelcome to Voidec installer! The declarative version of Void. Good luck!\e[0m"

REPO=https://repo-default.voidlinux.org/current
ARCH=x86_64

echo ""
lsblk
echo ""

read -p "Do you have your partitions ready? [Y/n]: " answer

if [[ "$answer" =~ ^[Nn]$ ]]; then
    echo ""
    echo "This is the partitioning script. We will start by selecting the boot type of your computer"
    while true; do
        echo -n "Your computer has: [BIOS/UEFI] "
        read bootype
        if [ "$bootype" == "BIOS" ]; then
            break
        elif [ "$bootype" == "UEFI" ]; then
            break
        else
            echo "$bootype is not a valid option... restarting."
        fi
    done
    echo "The boot type is $bootype"
    echo "These are your disks:"
    lsblk
    echo -n "Where are you going to install Voidec?: /dev/"
    read disk
    if [ "$bootype" == "BIOS" ]; then
        parted -s /dev/$disk mklabel msdos
        parted -s /dev/$disk unit GB mkpart primary ext4 0% 100%
        lsblk
        echo -n "Enter your root partition: /dev/"
        read root
        mkfs.ext4 /dev/$root
    else
        parted -s /dev/$disk mklabel gpt
        parted -s /dev/$disk unit GB mkpart mainroot ext4 1GB 100%
        parted -s /dev/$disk unit GB mkpart efiboot fat32 0% 1GB
        parted -s /dev/$disk unit GB set 2 esp on
        echo "Now let's make the file systems"
        lsblk
        echo -n "Which is your boot partition? /dev/"
        read boot
        mkfs.fat -F 32 /dev/$boot
        lsblk
        echo -n "Which is your root partition? /dev/"
        read root
        mkfs.ext4 /dev/$root
    fi

    mkdir /mnt
    mount /dev/$root /mnt
    if [ "$bootype" == "UEFI" ]; then
        mkdir -p /mnt/boot/efi
        mount /dev/$boot /mnt/boot/efi
    fi
else
    while true; do
        echo ""
        lsblk -f
        echo ""
        read -p "Are the partitions already mounted? (/mnt & /mnt/boot/efi)? [y/n]: " answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            break
        elif [ "$answer" = "n" ] || [ "$answer" = "N" ]; then
            mkdir /mnt
            read -p "What's your root partition?: /dev/" root
            read -p "What's your boot partition?: /dev/" boot
            mount /dev/$root /mnt
            mkdir -p /mnt/boot/efi
            mount /dev/$boot /mnt/boot/efi
            break
        else
            echo "Not a valid option"
        fi
    done
fi

echo ""
echo "Partitioning is done and partitions are mounted."

read -p "Let's proceed with installation. [Enter to continue] "
echo ""
echo "Copying the RSA keys"
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys/

XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" base-system NetworkManager

echo "Generating fstab"
xgenfstab -U /mnt > /mnt/etc/fstab


echo "Now we must enter the chroot"
cp /rebuild.sh /mnt
cp /voidecinstaller2.sh /mnt
xchroot /mnt /voidecinstaller2.sh 

